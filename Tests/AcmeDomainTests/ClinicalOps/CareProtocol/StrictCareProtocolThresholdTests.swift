@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolThresholdTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newStrictCareProtocolThreshold("code-274", name: "name-193")
        #expect(item.status == ClinicalOps.StrictCareProtocolThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newStrictCareProtocolThreshold("code-274", name: "name-193")
        try item.moveTo(ClinicalOps.StrictCareProtocolThresholdStatus.running)
        #expect(item.status == ClinicalOps.StrictCareProtocolThresholdStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newStrictCareProtocolThreshold("code-274", name: "name-193")
        item.status = ClinicalOps.StrictCareProtocolThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictCareProtocolThresholdStatus.new) }
    }
}
