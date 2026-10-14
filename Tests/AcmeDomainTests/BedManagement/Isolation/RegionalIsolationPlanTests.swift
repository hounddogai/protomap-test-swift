@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationPlanTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newRegionalIsolationPlan("code-629", title: "title-279")
        #expect(item.status == BedManagement.RegionalIsolationPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newRegionalIsolationPlan("code-629", title: "title-279")
        try item.moveTo(BedManagement.RegionalIsolationPlanStatus.ready)
        #expect(item.status == BedManagement.RegionalIsolationPlanStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newRegionalIsolationPlan("code-629", title: "title-279")
        item.status = BedManagement.RegionalIsolationPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalIsolationPlanStatus.idle) }
    }
}
