@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapBatchTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCappedCareGapBatch("code-357", name: "name-786")
        #expect(item.status == CareManagement.CappedCareGapBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newCappedCareGapBatch("code-357", name: "name-786")
        try item.moveTo(CareManagement.CappedCareGapBatchStatus.running)
        #expect(item.status == CareManagement.CappedCareGapBatchStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCappedCareGapBatch("code-357", name: "name-786")
        item.status = CareManagement.CappedCareGapBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedCareGapBatchStatus.new) }
    }
}
