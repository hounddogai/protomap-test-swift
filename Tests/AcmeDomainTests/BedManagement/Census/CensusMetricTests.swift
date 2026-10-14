@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusMetricTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCensusMetric("code-636", name: "name-935")
        #expect(item.status == BedManagement.CensusMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newCensusMetric("code-636", name: "name-935")
        try item.moveTo(BedManagement.CensusMetricStatus.completed)
        #expect(item.status == BedManagement.CensusMetricStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCensusMetric("code-636", name: "name-935")
        item.status = BedManagement.CensusMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusMetricStatus.planned) }
    }
}
