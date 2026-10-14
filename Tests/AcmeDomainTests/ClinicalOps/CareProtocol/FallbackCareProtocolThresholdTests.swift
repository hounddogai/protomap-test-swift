@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolThresholdTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newFallbackCareProtocolThreshold("code-317", title: "title-358")
        #expect(item.status == ClinicalOps.FallbackCareProtocolThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newFallbackCareProtocolThreshold("code-317", title: "title-358")
        try item.moveTo(ClinicalOps.FallbackCareProtocolThresholdStatus.granted)
        #expect(item.status == ClinicalOps.FallbackCareProtocolThresholdStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newFallbackCareProtocolThreshold("code-317", title: "title-358")
        item.status = ClinicalOps.FallbackCareProtocolThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackCareProtocolThresholdStatus.requested) }
    }
}
