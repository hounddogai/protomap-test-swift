@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyCareProtocolDigestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newLegacyCareProtocolDigest("code-7", title: "title-977")
        #expect(item.status == ClinicalOps.LegacyCareProtocolDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newLegacyCareProtocolDigest("code-7", title: "title-977")
        try item.moveTo(ClinicalOps.LegacyCareProtocolDigestStatus.pending)
        #expect(item.status == ClinicalOps.LegacyCareProtocolDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newLegacyCareProtocolDigest("code-7", title: "title-977")
        item.status = ClinicalOps.LegacyCareProtocolDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyCareProtocolDigestStatus.draft) }
    }
}
