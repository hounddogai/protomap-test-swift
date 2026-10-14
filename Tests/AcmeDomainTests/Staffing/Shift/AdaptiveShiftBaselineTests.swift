@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftBaselineTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAdaptiveShiftBaseline("code-601", name: "name-641")
        #expect(item.status == Staffing.AdaptiveShiftBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newAdaptiveShiftBaseline("code-601", name: "name-641")
        try item.moveTo(Staffing.AdaptiveShiftBaselineStatus.withdrawn)
        #expect(item.status == Staffing.AdaptiveShiftBaselineStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAdaptiveShiftBaseline("code-601", name: "name-641")
        item.status = Staffing.AdaptiveShiftBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveShiftBaselineStatus.proposed) }
    }
}
