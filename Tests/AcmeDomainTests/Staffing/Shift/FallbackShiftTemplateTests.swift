@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftTemplateTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackShiftTemplate("code-637", label: "label-316")
        #expect(item.status == Staffing.FallbackShiftTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newFallbackShiftTemplate("code-637", label: "label-316")
        try item.moveTo(Staffing.FallbackShiftTemplateStatus.reopened)
        #expect(item.status == Staffing.FallbackShiftTemplateStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackShiftTemplate("code-637", label: "label-316")
        item.status = Staffing.FallbackShiftTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackShiftTemplateStatus.`open`) }
    }
}
