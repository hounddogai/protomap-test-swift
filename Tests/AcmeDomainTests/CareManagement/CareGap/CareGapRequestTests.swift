@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapRequestTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newCareGapRequest("code-202", name: "name-374")
        #expect(item.status == CareManagement.CareGapRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newCareGapRequest("code-202", name: "name-374")
        try item.moveTo(CareManagement.CareGapRequestStatus.completed)
        #expect(item.status == CareManagement.CareGapRequestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newCareGapRequest("code-202", name: "name-374")
        item.status = CareManagement.CareGapRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapRequestStatus.planned) }
    }
}
