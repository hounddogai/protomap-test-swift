@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferPlanTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newFallbackTransferPlan("code-78", label: "label-944")
        #expect(item.status == BedManagement.FallbackTransferPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newFallbackTransferPlan("code-78", label: "label-944")
        try item.moveTo(BedManagement.FallbackTransferPlanStatus.approved)
        #expect(item.status == BedManagement.FallbackTransferPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newFallbackTransferPlan("code-78", label: "label-944")
        item.status = BedManagement.FallbackTransferPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackTransferPlanStatus.proposed) }
    }
}
