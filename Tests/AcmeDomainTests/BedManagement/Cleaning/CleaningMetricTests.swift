@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMetricTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningMetric("code-211", title: "title-519")
        #expect(item.status == BedManagement.CleaningMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCleaningMetric("code-211", title: "title-519")
        try item.moveTo(BedManagement.CleaningMetricStatus.queued)
        #expect(item.status == BedManagement.CleaningMetricStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningMetric("code-211", title: "title-519")
        item.status = BedManagement.CleaningMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningMetricStatus.new) }
    }
}
