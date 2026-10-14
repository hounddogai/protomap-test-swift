@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultCareGapAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newDefaultCareGapAssignment("code-291", name: "name-77")
        #expect(item.status == CareManagement.DefaultCareGapAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newDefaultCareGapAssignment("code-291", name: "name-77")
        try item.moveTo(CareManagement.DefaultCareGapAssignmentStatus.inProgress)
        #expect(item.status == CareManagement.DefaultCareGapAssignmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newDefaultCareGapAssignment("code-291", name: "name-77")
        item.status = CareManagement.DefaultCareGapAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultCareGapAssignmentStatus.planned) }
    }
}
