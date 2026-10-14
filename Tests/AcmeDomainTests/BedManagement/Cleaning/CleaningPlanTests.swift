@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPlanTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningPlan("code-92", title: "title-536")
        #expect(item.status == BedManagement.CleaningPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newCleaningPlan("code-92", title: "title-536")
        try item.moveTo(BedManagement.CleaningPlanStatus.running)
        #expect(item.status == BedManagement.CleaningPlanStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningPlan("code-92", title: "title-536")
        item.status = BedManagement.CleaningPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningPlanStatus.new) }
    }
}
