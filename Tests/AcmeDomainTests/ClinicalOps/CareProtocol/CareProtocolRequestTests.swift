@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRequestTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolRequest("code-77", name: "name-222")
        #expect(item.status == ClinicalOps.CareProtocolRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newCareProtocolRequest("code-77", name: "name-222")
        try item.moveTo(ClinicalOps.CareProtocolRequestStatus.ready)
        #expect(item.status == ClinicalOps.CareProtocolRequestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolRequest("code-77", name: "name-222")
        item.status = ClinicalOps.CareProtocolRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolRequestStatus.idle) }
    }
}
