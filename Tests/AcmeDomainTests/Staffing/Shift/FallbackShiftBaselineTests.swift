@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftBaselineTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackShiftBaseline("code-671", name: "name-271")
        #expect(item.status == Staffing.FallbackShiftBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newFallbackShiftBaseline("code-671", name: "name-271")
        try item.moveTo(Staffing.FallbackShiftBaselineStatus.resolved)
        #expect(item.status == Staffing.FallbackShiftBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackShiftBaseline("code-671", name: "name-271")
        item.status = Staffing.FallbackShiftBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackShiftBaselineStatus.`open`) }
    }
}
