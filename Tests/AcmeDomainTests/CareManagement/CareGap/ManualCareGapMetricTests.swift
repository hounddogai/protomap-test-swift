@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapMetricTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        #expect(item.status == CareManagement.ManualCareGapMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        try item.moveTo(CareManagement.ManualCareGapMetricStatus.ready)
        #expect(item.status == CareManagement.ManualCareGapMetricStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        item.status = CareManagement.ManualCareGapMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualCareGapMetricStatus.idle) }
    }
}
