@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureMappingTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newManualClosureMapping("code-725", title: "title-569")
        #expect(item.status == Referrals.ManualClosureMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newManualClosureMapping("code-725", title: "title-569")
        try item.moveTo(Referrals.ManualClosureMappingStatus.draining)
        #expect(item.status == Referrals.ManualClosureMappingStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newManualClosureMapping("code-725", title: "title-569")
        item.status = Referrals.ManualClosureMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualClosureMappingStatus.idle) }
    }
}
