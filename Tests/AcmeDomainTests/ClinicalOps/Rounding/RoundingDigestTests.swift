@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingDigestTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRoundingDigest("code-544", name: "name-340")
        #expect(item.status == ClinicalOps.RoundingDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newRoundingDigest("code-544", name: "name-340")
        try item.moveTo(ClinicalOps.RoundingDigestStatus.cancelled)
        #expect(item.status == ClinicalOps.RoundingDigestStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRoundingDigest("code-544", name: "name-340")
        item.status = ClinicalOps.RoundingDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingDigestStatus.planned) }
    }
}
