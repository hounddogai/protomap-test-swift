@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newTieredCareGapAdjustment("code-652", title: "title-863")
        #expect(item.status == CareManagement.TieredCareGapAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newTieredCareGapAdjustment("code-652", title: "title-863")
        try item.moveTo(CareManagement.TieredCareGapAdjustmentStatus.granted)
        #expect(item.status == CareManagement.TieredCareGapAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newTieredCareGapAdjustment("code-652", title: "title-863")
        item.status = CareManagement.TieredCareGapAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredCareGapAdjustmentStatus.requested) }
    }
}
