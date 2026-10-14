@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveDischargePlanTierTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newAdaptiveDischargePlanTier("code-170", name: "name-873")
        #expect(item.status == BedManagement.AdaptiveDischargePlanTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newAdaptiveDischargePlanTier("code-170", name: "name-873")
        try item.moveTo(BedManagement.AdaptiveDischargePlanTierStatus.inProgress)
        #expect(item.status == BedManagement.AdaptiveDischargePlanTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newAdaptiveDischargePlanTier("code-170", name: "name-873")
        item.status = BedManagement.AdaptiveDischargePlanTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveDischargePlanTierStatus.planned) }
    }
}
