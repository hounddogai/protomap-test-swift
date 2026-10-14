@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationGroupTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRevocationGroup("code-113", label: "label-846")
        #expect(item.status == Consent.RevocationGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newRevocationGroup("code-113", label: "label-846")
        try item.moveTo(Consent.RevocationGroupStatus.ready)
        #expect(item.status == Consent.RevocationGroupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRevocationGroup("code-113", label: "label-846")
        item.status = Consent.RevocationGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationGroupStatus.idle) }
    }
}
