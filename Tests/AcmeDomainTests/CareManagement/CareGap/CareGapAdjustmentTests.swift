@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAdjustmentTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCareGapAdjustment("code-532", label: "label-948")
        #expect(item.status == CareManagement.CareGapAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newCareGapAdjustment("code-532", label: "label-948")
        try item.moveTo(CareManagement.CareGapAdjustmentStatus.running)
        #expect(item.status == CareManagement.CareGapAdjustmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCareGapAdjustment("code-532", label: "label-948")
        item.status = CareManagement.CareGapAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapAdjustmentStatus.new) }
    }
}
