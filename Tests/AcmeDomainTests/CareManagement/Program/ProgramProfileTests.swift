@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProfileTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newProgramProfile("code-606", label: "label-310")
        #expect(item.status == CareManagement.ProgramProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newProgramProfile("code-606", label: "label-310")
        try item.moveTo(CareManagement.ProgramProfileStatus.inReview)
        #expect(item.status == CareManagement.ProgramProfileStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newProgramProfile("code-606", label: "label-310")
        item.status = CareManagement.ProgramProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramProfileStatus.`open`) }
    }
}
