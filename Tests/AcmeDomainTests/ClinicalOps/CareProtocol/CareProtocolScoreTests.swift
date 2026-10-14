@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolScoreTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolScore("code-251", title: "title-135")
        #expect(item.status == ClinicalOps.CareProtocolScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newCareProtocolScore("code-251", title: "title-135")
        try item.moveTo(ClinicalOps.CareProtocolScoreStatus.queued)
        #expect(item.status == ClinicalOps.CareProtocolScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolScore("code-251", title: "title-135")
        item.status = ClinicalOps.CareProtocolScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolScoreStatus.new) }
    }
}
