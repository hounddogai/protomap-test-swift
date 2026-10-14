@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolOverrideTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolOverride("code-631", title: "title-144")
        #expect(item.status == ClinicalOps.CareProtocolOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newCareProtocolOverride("code-631", title: "title-144")
        try item.moveTo(ClinicalOps.CareProtocolOverrideStatus.draining)
        #expect(item.status == ClinicalOps.CareProtocolOverrideStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolOverride("code-631", title: "title-144")
        item.status = ClinicalOps.CareProtocolOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolOverrideStatus.idle) }
    }
}
