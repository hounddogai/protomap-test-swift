@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramTemplateTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newProgramTemplate("code-251", name: "name-239")
        #expect(item.status == CareManagement.ProgramTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newProgramTemplate("code-251", name: "name-239")
        try item.moveTo(CareManagement.ProgramTemplateStatus.approved)
        #expect(item.status == CareManagement.ProgramTemplateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newProgramTemplate("code-251", name: "name-239")
        item.status = CareManagement.ProgramTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramTemplateStatus.proposed) }
    }
}
