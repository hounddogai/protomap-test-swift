@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDigestTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureDigest("code-402", label: "label-400")
        #expect(item.status == Consent.DisclosureDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newDisclosureDigest("code-402", label: "label-400")
        try item.moveTo(Consent.DisclosureDigestStatus.cancelled)
        #expect(item.status == Consent.DisclosureDigestStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureDigest("code-402", label: "label-400")
        item.status = Consent.DisclosureDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureDigestStatus.planned) }
    }
}
