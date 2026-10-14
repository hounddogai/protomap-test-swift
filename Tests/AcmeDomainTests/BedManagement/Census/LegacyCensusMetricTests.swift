@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMetricTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLegacyCensusMetric("code-588", name: "name-939")
        #expect(item.status == BedManagement.LegacyCensusMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newLegacyCensusMetric("code-588", name: "name-939")
        try item.moveTo(BedManagement.LegacyCensusMetricStatus.reopened)
        #expect(item.status == BedManagement.LegacyCensusMetricStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLegacyCensusMetric("code-588", name: "name-939")
        item.status = BedManagement.LegacyCensusMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusMetricStatus.`open`) }
    }
}
