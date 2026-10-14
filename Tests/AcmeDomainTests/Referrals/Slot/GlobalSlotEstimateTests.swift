@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newGlobalSlotEstimate("code-24", title: "title-139")
        #expect(item.status == Referrals.GlobalSlotEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newGlobalSlotEstimate("code-24", title: "title-139")
        try item.moveTo(Referrals.GlobalSlotEstimateStatus.inProgress)
        #expect(item.status == Referrals.GlobalSlotEstimateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newGlobalSlotEstimate("code-24", title: "title-139")
        item.status = Referrals.GlobalSlotEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalSlotEstimateStatus.planned) }
    }
}
