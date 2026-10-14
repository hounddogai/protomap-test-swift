@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimBatchTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newLenientClaimBatch("code-934", title: "title-950")
        #expect(item.status == RevenueCycle.LenientClaimBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newLenientClaimBatch("code-934", title: "title-950")
        try item.moveTo(RevenueCycle.LenientClaimBatchStatus.draining)
        #expect(item.status == RevenueCycle.LenientClaimBatchStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newLenientClaimBatch("code-934", title: "title-950")
        item.status = RevenueCycle.LenientClaimBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientClaimBatchStatus.idle) }
    }
}
