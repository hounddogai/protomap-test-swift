@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPlanTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newProgramPlan("code-595", title: "title-500")
        #expect(item.status == CareManagement.ProgramPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newProgramPlan("code-595", title: "title-500")
        try item.moveTo(CareManagement.ProgramPlanStatus.draining)
        #expect(item.status == CareManagement.ProgramPlanStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newProgramPlan("code-595", title: "title-500")
        item.status = CareManagement.ProgramPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramPlanStatus.idle) }
    }
}
