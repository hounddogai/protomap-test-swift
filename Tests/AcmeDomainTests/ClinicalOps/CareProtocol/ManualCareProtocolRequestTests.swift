@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualCareProtocolRequestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newManualCareProtocolRequest("code-921", name: "name-106")
        #expect(item.status == ClinicalOps.ManualCareProtocolRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newManualCareProtocolRequest("code-921", name: "name-106")
        try item.moveTo(ClinicalOps.ManualCareProtocolRequestStatus.withdrawn)
        #expect(item.status == ClinicalOps.ManualCareProtocolRequestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newManualCareProtocolRequest("code-921", name: "name-106")
        item.status = ClinicalOps.ManualCareProtocolRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualCareProtocolRequestStatus.proposed) }
    }
}
