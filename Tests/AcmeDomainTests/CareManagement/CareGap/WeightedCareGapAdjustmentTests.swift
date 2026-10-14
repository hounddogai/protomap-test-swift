@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newWeightedCareGapAdjustment("code-971", title: "title-801")
        #expect(item.status == CareManagement.WeightedCareGapAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newWeightedCareGapAdjustment("code-971", title: "title-801")
        try item.moveTo(CareManagement.WeightedCareGapAdjustmentStatus.expired)
        #expect(item.status == CareManagement.WeightedCareGapAdjustmentStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newWeightedCareGapAdjustment("code-971", title: "title-801")
        item.status = CareManagement.WeightedCareGapAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedCareGapAdjustmentStatus.requested) }
    }
}
