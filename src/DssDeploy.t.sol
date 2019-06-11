pragma solidity >=0.5.0;

import "./DssDeploy.t.base.sol";

import "./join.sol";

import "./token1.sol";
import "./token2.sol";
import "./token3.sol";
import "./token4.sol";
import "./token5.sol";

contract DssDeployTest is DssDeployTestBase {
    function testDeploy() public {
        deploy();
    }

    function testFailMissingVat() public {
        dssDeploy.deployTaxationAndAuctions(address(gov));
    }

    function testFailMissingTaxationAndAuctions() public {
        dssDeploy.deployVat();
        dssDeploy.deployDai(99);
        dssDeploy.deployLiquidator();
    }

    function testFailMissingLiquidator() public {
        dssDeploy.deployVat();
        dssDeploy.deployDai(99);
        dssDeploy.deployTaxationAndAuctions(address(gov));
        dssDeploy.deployEnd(address(gov), address(0x0), 10);
    }

    function testFailMissingEnd() public {
        dssDeploy.deployVat();
        dssDeploy.deployDai(99);
        dssDeploy.deployTaxationAndAuctions(address(gov));
        dssDeploy.deployPause(0, authority);
    }

    function testJoinETH() public {
        deploy();
        assertEq(vat.gem("ETH", address(this)), 0);
        weth.deposit.value(1 ether)();
        assertEq(weth.balanceOf(address(this)), 1 ether);
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
    }

    function testJoinGem() public {
        deploy();
        col.mint(1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 0);
        assertEq(vat.gem("COL", address(this)), 1 ether);
    }

    function testExitETH() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        ethJoin.exit(address(this), 1 ether);
        assertEq(vat.gem("ETH", address(this)), 0);
    }

    function testExitGem() public {
        deploy();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        colJoin.exit(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
    }

    function testFrobDrawDai() public {
        deploy();
        assertEq(dai.balanceOf(address(this)), 0);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", address(this)), 0.5 ether);
        assertEq(vat.dai(address(this)), mul(ONE, 60 ether));

        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(address(this)), 0);
    }

    function testFrobDrawDaiGem() public {
        deploy();
        assertEq(dai.balanceOf(address(this)), 0);
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);

        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20 ether);

        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 20 ether);
        assertEq(dai.balanceOf(address(this)), 20 ether);
    }

    function testFrobDrawDaiLimit() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // 0.5 * 300 / 1.5 = 100 DAI max
    }

    function testFrobDrawDaiGemLimit() public {
        deploy();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether); // 0.5 * 45 / 1.1 = 20.454545454545454545 DAI max
    }

    function testFailFrobDrawDaiLimit() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether + 1);
    }

    function testFailFrobDrawDaiGemLimit() public {
        deploy();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether + 1);
    }

    function testFrobPaybackDai() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        dai.approve(address(daiJoin), uint(-1));
        daiJoin.join(address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 0);

        assertEq(vat.dai(address(this)), mul(ONE, 60 ether));
        vat.frob("ETH", address(this), address(this), address(this), 0 ether, -60 ether);
        assertEq(vat.dai(address(this)), 0);
    }

    function testFrobFromAnotherUser() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.hope(address(user1));
        user1.doFrob(address(vat), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailFrobDust() public {
        deploy();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 19 ether);
    }

    function testFailFrobFromAnotherUser() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        user1.doFrob(address(vat), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailBite() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // Maximun DAI

        cat.bite("ETH", address(this));
    }

    function testBite() public {
        deploy();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun DAI generated

        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 200 ether);
        cat.bite("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function testBitePartial() public {
        deploy();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(10 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 10 ether);
        vat.frob("ETH", address(this), address(this), address(this), 10 ether, 2000 ether); // Maximun DAI generated

        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 10 ether);
        assertEq(art, 2000 ether);
        cat.bite("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 9 ether);
        assertEq(art, 1800 ether);
    }

    function testFlip() public {
        deploy();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun DAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        assertEq(vat.gem("ETH", address(ethFlip)), 0);
        uint batchId = cat.bite("ETH", address(this));
        assertEq(vat.gem("ETH", address(ethFlip)), 1 ether);
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doFrob(address(vat), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(100 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(140 ether));
        user1.doTend(address(ethFlip), batchId, 1 ether, rad(180 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(200 ether));

        user1.doDent(address(ethFlip), batchId, 0.8 ether, rad(200 ether));
        user2.doDent(address(ethFlip), batchId, 0.7 ether, rad(200 ether));
        hevm.warp(ethFlip.ttl() - 1);
        user1.doDent(address(ethFlip), batchId, 0.6 ether, rad(200 ether));
        hevm.warp(now + ethFlip.ttl() + 1);
        user1.doDeal(address(ethFlip), batchId);
    }

    function testFlop() public {
        deploy();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun DAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        uint48 eraBite = uint48(now);
        uint batchId = cat.bite("ETH", address(this));
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doFrob(address(vat), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(100 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(140 ether));
        user1.doTend(address(ethFlip), batchId, 1 ether, rad(180 ether));

        hevm.warp(now + ethFlip.ttl() + 1);
        user1.doDeal(address(ethFlip), batchId);

        vow.flog(eraBite);
        vow.heal(rad(180 ether));
        this.file(address(vow), bytes32("sump"), rad(20 ether));
        batchId = vow.flop();

        (uint bid,,,,,) = flop.bids(batchId);
        assertEq(bid, rad(20 ether));
        user1.doHope(address(vat), address(flop));
        user2.doHope(address(vat), address(flop));
        user1.doDent(address(flop), batchId, 0.6 ether, rad(20 ether));
        hevm.warp(now + flop.ttl() - 1);
        user2.doDent(address(flop), batchId, 0.2 ether, rad(20 ether));
        user1.doDent(address(flop), batchId, 0.16 ether, rad(20 ether));
        hevm.warp(now + flop.ttl() + 1);
        uint prevGovSupply = gov.totalSupply();
        user1.doDeal(address(flop), batchId);
        assertEq(gov.totalSupply(), prevGovSupply + 0.16 ether);
        vow.kiss(rad(20 ether));
        assertEq(vow.Joy(), 0);
        assertEq(vow.Woe(), 0);
        assertEq(vow.Awe(), 0);
    }

    function testFlap() public {
        deploy();
        this.file(address(jug), bytes32("ETH"), bytes32("duty"), uint(1.05 * 10 ** 27));
        weth.deposit.value(0.5 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 0.5 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.1 ether, 10 ether);
        hevm.warp(now + 1);
        assertEq(vow.Joy(), 0);
        jug.drip("ETH");
        assertEq(vow.Joy(), rad(10 * 0.05 ether));
        this.file(address(vow), bytes32("bump"), rad(0.05 ether));
        uint batchId = vow.flap();

        (,uint lot,,,,) = flap.bids(batchId);
        assertEq(lot, rad(0.05 ether));
        user1.doApprove(address(gov), address(flap));
        user2.doApprove(address(gov), address(flap));
        gov.transfer(address(user1), 1 ether);
        gov.transfer(address(user2), 1 ether);

        assertEq(dai.balanceOf(address(user1)), 0);
        assertEq(gov.balanceOf(address(0)), 0);

        user1.doTend(address(flap), batchId, rad(0.05 ether), 0.001 ether);
        user2.doTend(address(flap), batchId, rad(0.05 ether), 0.0015 ether);
        user1.doTend(address(flap), batchId, rad(0.05 ether), 0.0016 ether);

        assertEq(gov.balanceOf(address(user1)), 1 ether - 0.0016 ether);
        assertEq(gov.balanceOf(address(user2)), 1 ether);
        hevm.warp(now + flap.ttl() + 1);
        user1.doDeal(address(flap), batchId);
        assertEq(gov.balanceOf(address(0)), 0.0016 ether);
        user1.doHope(address(vat), address(daiJoin));
        user1.doDaiExit(address(daiJoin), address(user1), 0.05 ether);
        assertEq(dai.balanceOf(address(user1)), 0.05 ether);
    }

    function testEnd() public {
        deploy();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(2 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 2 ether);
        vat.frob("ETH", address(this), address(this), address(this), 2 ether, 400 ether); // Maximun DAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        uint batchId = cat.bite("ETH", address(this)); // The CDP remains unsafe after 1st batch is bitten
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        col.mint(100 ether);
        col.approve(address(colJoin), 100 ether);
        colJoin.join(address(user2), 100 ether);
        user2.doFrob(address(vat), "COL", address(user2), address(user2), address(user2), 100 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(100 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(140 ether));
        assertEq(vat.dai(address(user2)), rad(860 ether));

        this.cage(address(end));
        this.cage(address(end), "ETH");
        this.cage(address(end), "COL");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 200 ether);

        end.skip("ETH", batchId);
        assertEq(vat.dai(address(user2)), rad(1000 ether));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 2 ether);
        assertEq(art, 400 ether);

        end.skim("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        uint remainInkVal = 2 ether - 400 * end.tag("ETH") / 10 ** 9; // 2 ETH (deposited) - 400 DAI debt * ETH cage price
        assertEq(ink, remainInkVal);
        assertEq(art, 0);

        end.free("ETH");
        (ink,) = vat.urns("ETH", address(this));
        assertEq(ink, 0);

        (ink, art) = vat.urns("ETH", address(user1));
        assertEq(ink, 10 ether);
        assertEq(art, 1000 ether);

        end.skim("ETH", address(user1));
        end.skim("COL", address(user2));

        vow.heal(vat.dai(address(vow)));

        end.thaw();

        end.flow("ETH");
        end.flow("COL");

        vat.hope(address(end));
        end.pack(400 ether);

        assertEq(vat.gem("ETH", address(this)), remainInkVal);
        assertEq(vat.gem("COL", address(this)), 0);
        end.cash("ETH", 400 ether);
        end.cash("COL", 400 ether);
        assertEq(vat.gem("ETH", address(this)), remainInkVal + 400 * end.fix("ETH") / 10 ** 9);
        assertEq(vat.gem("COL", address(this)), 400 * end.fix("COL") / 10 ** 9);
    }

    function testFireESM() public {
        deploy();
        gov.mint(address(user1), 10);

        user1.doESMJoin(address(gov), address(esm), 10);
        esm.fire();
    }

    function testDsr() public {
        deploy();
        this.file(address(jug), bytes32("ETH"), bytes32("duty"), uint(1.1 * 10 ** 27));
        this.file(address(pot), "dsr", uint(1.05 * 10 ** 27));
        weth.deposit.value(0.5 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 0.5 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.1 ether, 10 ether);
        assertEq(vat.dai(address(this)), mul(10 ether, ONE));
        vat.hope(address(pot));
        pot.join(10 ether);
        hevm.warp(now + 1);
        jug.drip("ETH");
        pot.drip();
        pot.exit(10 ether);
        assertEq(vat.dai(address(this)), mul(10.5 ether, ONE));
    }

    function testFork() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 0.25 ether, 15 ether);

        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 0.75 ether);
        assertEq(art, 45 ether);

        (ink, art) = vat.urns("ETH", address(user1));
        assertEq(ink, 0.25 ether);
        assertEq(art, 15 ether);
    }

    function testFailFork() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        vat.fork("ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testForkFromOtherUsr() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        vat.hope(address(user1));
        user1.doFork(address(vat), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailForkFromOtherUsr() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        user1.doFork(address(vat), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailForkUnsafeSrc() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        vat.fork("ETH", address(this), address(user1), 0.9 ether, 1 ether);
    }

    function testFailForkUnsafeDst() public {
        deploy();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        vat.fork("ETH", address(this), address(user1), 0.1 ether, 59 ether);
    }

    function testFailForkDustSrc() public {
        deploy();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 50 ether, 19 ether);
    }

    function testFailForkDustDst() public {
        deploy();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 50 ether, 41 ether);
    }

    function testSetPauseAuthority() public {
        deploy();
        assertEq(address(pause.authority()), address(authority));
        this.setAuthority(address(123));
        assertEq(address(pause.authority()), address(123));
    }

    function testSetPauseDelay() public {
        deploy();
        assertEq(pause.delay(), 0);
        this.setDelay(5);
        assertEq(pause.delay(), 5);
    }

    function testSetPauseAuthorityAndDelay() public {
        deploy();
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.delay(), 0);
        this.setAuthorityAndDelay(address(123), 5);
        assertEq(address(pause.authority()), address(123));
        assertEq(pause.delay(), 5);
    }

    function testTokens() public {
        deployKeepAuth();
        DSValue pip = new DSValue();
        Token1 token1 = new Token1(100 ether);
        GemJoin col1Join = new GemJoin(address(vat), "COL1", address(token1));
        Token2 token2 = new Token2(100 ether);
        GemJoin col2Join = new GemJoin(address(vat), "COL2", address(token2));
        Token3 token3 = new Token3(100 ether);
        GemJoin2 col3Join = new GemJoin2(address(vat), "COL3", address(token3));
        Token4 token4 = new Token4(100 ether);
        GemJoin col4Join = new GemJoin(address(vat), "COL4", address(token4));
        Token5 token5 = new Token5(100 ether);
        GemJoin3 col5Join = new GemJoin3(address(vat), "COL5", address(token5));

        dssDeploy.deployCollateral("COL1", address(col1Join), address(pip));
        dssDeploy.deployCollateral("COL2", address(col2Join), address(pip));
        dssDeploy.deployCollateral("COL3", address(col3Join), address(pip));
        dssDeploy.deployCollateral("COL4", address(col4Join), address(pip));
        dssDeploy.deployCollateral("COL5", address(col5Join), address(pip));

        token1.approve(address(col1Join), uint(-1));
        assertEq(token1.balanceOf(address(col1Join)), 0);
        assertEq(vat.gem("COL1", address(this)), 0);
        col1Join.join(address(this), 10);
        assertEq(token1.balanceOf(address(col1Join)), 10);
        assertEq(vat.gem("COL1", address(this)), 10);

        token2.approve(address(col2Join), uint(-1));
        assertEq(token2.balanceOf(address(col2Join)), 0);
        assertEq(vat.gem("COL2", address(this)), 0);
        col2Join.join(address(this), 10);
        assertEq(token2.balanceOf(address(col2Join)), 10);
        assertEq(vat.gem("COL2", address(this)), 10);

        token3.approve(address(col3Join), uint(-1));
        assertEq(token3.balanceOf(address(col3Join)), 0);
        assertEq(vat.gem("COL3", address(this)), 0);
        col3Join.join(address(this), 10);
        assertEq(token3.balanceOf(address(col3Join)), 10);
        assertEq(vat.gem("COL3", address(this)), 10);

        token4.approve(address(col4Join), uint(-1));
        assertEq(token1.balanceOf(address(col4Join)), 0);
        assertEq(vat.gem("COL4", address(this)), 0);
        col4Join.join(address(this), 10);
        assertEq(token4.balanceOf(address(col4Join)), 10);
        assertEq(vat.gem("COL4", address(this)), 10);

        token5.approve(address(col5Join), uint(-1));
        assertEq(token1.balanceOf(address(col5Join)), 0);
        assertEq(vat.gem("COL5", address(this)), 0);
        col5Join.join(address(this), 10);
        assertEq(token5.balanceOf(address(col5Join)), 10);
        assertEq(vat.gem("COL5", address(this)), 10 * 10 ** 9);
    }

    function testAuth() public {
        deployKeepAuth();

        // vat
        assertEq(vat.wards(address(dssDeploy)), 1);
        assertEq(vat.wards(address(ethJoin)), 1);
        assertEq(vat.wards(address(colJoin)), 1);
        assertEq(vat.wards(address(vow)), 1);
        assertEq(vat.wards(address(cat)), 1);
        assertEq(vat.wards(address(jug)), 1);
        assertEq(vat.wards(address(spotter)), 1);
        assertEq(vat.wards(address(end)), 1);
        assertEq(vat.wards(address(pause.proxy())), 1);

        // cat
        assertEq(cat.wards(address(dssDeploy)), 1);
        assertEq(cat.wards(address(end)), 1);
        assertEq(cat.wards(address(pause.proxy())), 1);

        // vow
        assertEq(vow.wards(address(dssDeploy)), 1);
        assertEq(vow.wards(address(cat)), 1);
        assertEq(vow.wards(address(end)), 1);
        assertEq(vow.wards(address(pause.proxy())), 1);

        // jug
        assertEq(jug.wards(address(dssDeploy)), 1);
        assertEq(jug.wards(address(pause.proxy())), 1);

        // pot
        assertEq(pot.wards(address(dssDeploy)), 1);
        assertEq(pot.wards(address(pause.proxy())), 1);

        // dai
        assertEq(dai.wards(address(dssDeploy)), 1);

        // spotter
        assertEq(spotter.wards(address(dssDeploy)), 1);
        assertEq(spotter.wards(address(pause.proxy())), 1);

        // flap
        assertEq(flap.wards(address(dssDeploy)), 1);
        assertEq(flap.wards(address(vow)), 1);
        assertEq(flap.wards(address(pause.proxy())), 1);

        // flop
        assertEq(flop.wards(address(dssDeploy)), 1);
        assertEq(flop.wards(address(vow)), 1);
        assertEq(flop.wards(address(pause.proxy())), 1);

        // end
        assertEq(end.wards(address(dssDeploy)), 1);
        assertEq(end.wards(address(pause.proxy())), 1);
        assertEq(end.wards(address(dssDeploy.esm())), 1);

        // flips
        assertEq(ethFlip.wards(address(dssDeploy)), 1);
        assertEq(ethFlip.wards(address(pause.proxy())), 1);
        assertEq(colFlip.wards(address(dssDeploy)), 1);
        assertEq(colFlip.wards(address(end)), 1);
        assertEq(colFlip.wards(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // dssDeploy
        assertEq(address(dssDeploy.authority()), address(authority));
        assertEq(dssDeploy.owner(), address(0));

        // root
        assertTrue(authority.isUserRoot(address(this)));

        dssDeploy.releaseAuth();
        dssDeploy.releaseAuthFlip("ETH");
        dssDeploy.releaseAuthFlip("COL");
        assertEq(vat.wards(address(dssDeploy)), 0);
        assertEq(cat.wards(address(dssDeploy)), 0);
        assertEq(vow.wards(address(dssDeploy)), 0);
        assertEq(jug.wards(address(dssDeploy)), 0);
        assertEq(pot.wards(address(dssDeploy)), 0);
        assertEq(dai.wards(address(dssDeploy)), 0);
        assertEq(spotter.wards(address(dssDeploy)), 0);
        assertEq(flap.wards(address(dssDeploy)), 0);
        assertEq(flop.wards(address(dssDeploy)), 0);
        assertEq(end.wards(address(dssDeploy)), 0);
        assertEq(ethFlip.wards(address(dssDeploy)), 0);
        assertEq(colFlip.wards(address(dssDeploy)), 0);
    }
}
