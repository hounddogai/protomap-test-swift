@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        #expect(item.status == CareManagement.RollingCareGapAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        try item.moveTo(CareManagement.RollingCareGapAdjustmentStatus.scheduled)
        #expect(item.status == CareManagement.RollingCareGapAdjustmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        item.status = CareManagement.RollingCareGapAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingCareGapAdjustmentStatus.planned) }
    }
}
