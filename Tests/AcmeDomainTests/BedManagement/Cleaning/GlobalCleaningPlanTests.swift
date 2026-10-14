@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningPlanTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newGlobalCleaningPlan("code-321", title: "title-582")
        #expect(item.status == BedManagement.GlobalCleaningPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newGlobalCleaningPlan("code-321", title: "title-582")
        try item.moveTo(BedManagement.GlobalCleaningPlanStatus.revoked)
        #expect(item.status == BedManagement.GlobalCleaningPlanStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newGlobalCleaningPlan("code-321", title: "title-582")
        item.status = BedManagement.GlobalCleaningPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCleaningPlanStatus.requested) }
    }
}
