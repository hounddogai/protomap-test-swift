@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationMetricTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newFallbackIsolationMetric("code-725", title: "title-263")
        #expect(item.status == BedManagement.FallbackIsolationMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newFallbackIsolationMetric("code-725", title: "title-263")
        try item.moveTo(BedManagement.FallbackIsolationMetricStatus.inProgress)
        #expect(item.status == BedManagement.FallbackIsolationMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newFallbackIsolationMetric("code-725", title: "title-263")
        item.status = BedManagement.FallbackIsolationMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackIsolationMetricStatus.planned) }
    }
}
