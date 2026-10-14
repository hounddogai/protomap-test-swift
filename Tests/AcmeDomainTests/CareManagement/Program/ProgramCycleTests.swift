@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramCycleTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newProgramCycle("code-24", title: "title-4")
        #expect(item.status == CareManagement.ProgramCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newProgramCycle("code-24", title: "title-4")
        try item.moveTo(CareManagement.ProgramCycleStatus.published)
        #expect(item.status == CareManagement.ProgramCycleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newProgramCycle("code-24", title: "title-4")
        item.status = CareManagement.ProgramCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramCycleStatus.created) }
    }
}
