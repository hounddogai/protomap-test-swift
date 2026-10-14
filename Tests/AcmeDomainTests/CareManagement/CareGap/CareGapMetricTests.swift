@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapMetricTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCareGapMetric("code-496", title: "title-912")
        #expect(item.status == CareManagement.CareGapMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newCareGapMetric("code-496", title: "title-912")
        try item.moveTo(CareManagement.CareGapMetricStatus.granted)
        #expect(item.status == CareManagement.CareGapMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCareGapMetric("code-496", title: "title-912")
        item.status = CareManagement.CareGapMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapMetricStatus.requested) }
    }
}
