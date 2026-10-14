@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRollupTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        #expect(item.status == Consent.RevocationRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        try item.moveTo(Consent.RevocationRollupStatus.ready)
        #expect(item.status == Consent.RevocationRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        item.status = Consent.RevocationRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationRollupStatus.idle) }
    }
}
