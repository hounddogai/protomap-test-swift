@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolEstimateTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolEstimate("code-635", label: "label-456")
        #expect(item.status == ClinicalOps.CareProtocolEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newCareProtocolEstimate("code-635", label: "label-456")
        try item.moveTo(ClinicalOps.CareProtocolEstimateStatus.warming)
        #expect(item.status == ClinicalOps.CareProtocolEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolEstimate("code-635", label: "label-456")
        item.status = ClinicalOps.CareProtocolEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolEstimateStatus.idle) }
    }
}
