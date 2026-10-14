@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolThresholdTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLenientCareProtocolThreshold("code-771", name: "name-236")
        #expect(item.status == ClinicalOps.LenientCareProtocolThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = ClinicalOps.newLenientCareProtocolThreshold("code-771", name: "name-236")
        try item.moveTo(ClinicalOps.LenientCareProtocolThresholdStatus.expired)
        #expect(item.status == ClinicalOps.LenientCareProtocolThresholdStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLenientCareProtocolThreshold("code-771", name: "name-236")
        item.status = ClinicalOps.LenientCareProtocolThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientCareProtocolThresholdStatus.requested) }
    }
}
