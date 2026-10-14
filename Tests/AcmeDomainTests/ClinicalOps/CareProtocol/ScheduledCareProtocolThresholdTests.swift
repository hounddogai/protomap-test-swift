@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolThresholdTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newScheduledCareProtocolThreshold("code-951", name: "name-908")
        #expect(item.status == ClinicalOps.ScheduledCareProtocolThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newScheduledCareProtocolThreshold("code-951", name: "name-908")
        try item.moveTo(ClinicalOps.ScheduledCareProtocolThresholdStatus.ready)
        #expect(item.status == ClinicalOps.ScheduledCareProtocolThresholdStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newScheduledCareProtocolThreshold("code-951", name: "name-908")
        item.status = ClinicalOps.ScheduledCareProtocolThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledCareProtocolThresholdStatus.idle) }
    }
}
