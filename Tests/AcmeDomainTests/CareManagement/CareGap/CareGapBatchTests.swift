@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBatchTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCareGapBatch("code-806", name: "name-917")
        #expect(item.status == CareManagement.CareGapBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newCareGapBatch("code-806", name: "name-917")
        try item.moveTo(CareManagement.CareGapBatchStatus.expired)
        #expect(item.status == CareManagement.CareGapBatchStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCareGapBatch("code-806", name: "name-917")
        item.status = CareManagement.CareGapBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapBatchStatus.requested) }
    }
}
