@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeMappingTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newRegionalOvertimeMapping("code-519", name: "name-289")
        #expect(item.status == Staffing.RegionalOvertimeMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newRegionalOvertimeMapping("code-519", name: "name-289")
        try item.moveTo(Staffing.RegionalOvertimeMappingStatus.pending)
        #expect(item.status == Staffing.RegionalOvertimeMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newRegionalOvertimeMapping("code-519", name: "name-289")
        item.status = Staffing.RegionalOvertimeMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalOvertimeMappingStatus.draft) }
    }
}
