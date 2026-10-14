@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveDischargePlanBaselineTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newAdaptiveDischargePlanBaseline("code-921", name: "name-222")
        #expect(item.status == BedManagement.AdaptiveDischargePlanBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newAdaptiveDischargePlanBaseline("code-921", name: "name-222")
        try item.moveTo(BedManagement.AdaptiveDischargePlanBaselineStatus.inProgress)
        #expect(item.status == BedManagement.AdaptiveDischargePlanBaselineStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newAdaptiveDischargePlanBaseline("code-921", name: "name-222")
        item.status = BedManagement.AdaptiveDischargePlanBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveDischargePlanBaselineStatus.planned) }
    }
}
