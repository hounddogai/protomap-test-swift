@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftTemplateTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        #expect(item.status == Staffing.DefaultShiftTemplateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        try item.moveTo(Staffing.DefaultShiftTemplateStatus.published)
        #expect(item.status == Staffing.DefaultShiftTemplateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        item.status = Staffing.DefaultShiftTemplateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultShiftTemplateStatus.created) }
    }
}
