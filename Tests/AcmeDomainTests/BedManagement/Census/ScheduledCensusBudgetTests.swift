@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusBudgetTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newScheduledCensusBudget("code-97", name: "name-153")
        #expect(item.status == BedManagement.ScheduledCensusBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newScheduledCensusBudget("code-97", name: "name-153")
        try item.moveTo(BedManagement.ScheduledCensusBudgetStatus.running)
        #expect(item.status == BedManagement.ScheduledCensusBudgetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newScheduledCensusBudget("code-97", name: "name-153")
        item.status = BedManagement.ScheduledCensusBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusBudgetStatus.new) }
    }
}
