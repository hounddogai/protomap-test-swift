@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGlobalCareGapAssignment("code-314", name: "name-842")
        #expect(item.status == CareManagement.GlobalCareGapAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newGlobalCareGapAssignment("code-314", name: "name-842")
        try item.moveTo(CareManagement.GlobalCareGapAssignmentStatus.completed)
        #expect(item.status == CareManagement.GlobalCareGapAssignmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGlobalCareGapAssignment("code-314", name: "name-842")
        item.status = CareManagement.GlobalCareGapAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalCareGapAssignmentStatus.planned) }
    }
}
