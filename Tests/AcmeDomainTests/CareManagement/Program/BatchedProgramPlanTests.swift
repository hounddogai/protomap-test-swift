@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramPlanTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newBatchedProgramPlan("code-520", name: "name-801")
        #expect(item.status == CareManagement.BatchedProgramPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newBatchedProgramPlan("code-520", name: "name-801")
        try item.moveTo(CareManagement.BatchedProgramPlanStatus.archived)
        #expect(item.status == CareManagement.BatchedProgramPlanStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newBatchedProgramPlan("code-520", name: "name-801")
        item.status = CareManagement.BatchedProgramPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedProgramPlanStatus.`open`) }
    }
}
