@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferMetricTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newFallbackTransferMetric("code-389", label: "label-580")
        #expect(item.status == BedManagement.FallbackTransferMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newFallbackTransferMetric("code-389", label: "label-580")
        try item.moveTo(BedManagement.FallbackTransferMetricStatus.rejected)
        #expect(item.status == BedManagement.FallbackTransferMetricStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newFallbackTransferMetric("code-389", label: "label-580")
        item.status = BedManagement.FallbackTransferMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackTransferMetricStatus.proposed) }
    }
}
