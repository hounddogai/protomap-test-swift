@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPlanTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newIsolationPlan("code-794", label: "label-111")
        #expect(item.status == BedManagement.IsolationPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newIsolationPlan("code-794", label: "label-111")
        try item.moveTo(BedManagement.IsolationPlanStatus.failed)
        #expect(item.status == BedManagement.IsolationPlanStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newIsolationPlan("code-794", label: "label-111")
        item.status = BedManagement.IsolationPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationPlanStatus.new) }
    }
}
