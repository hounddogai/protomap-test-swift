@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveWitnessDigestTests {
    @Test func startsInRequested() throws {
        let item = Consent.newAdaptiveWitnessDigest("code-947", title: "title-877")
        #expect(item.status == Consent.AdaptiveWitnessDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newAdaptiveWitnessDigest("code-947", title: "title-877")
        try item.moveTo(Consent.AdaptiveWitnessDigestStatus.expired)
        #expect(item.status == Consent.AdaptiveWitnessDigestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newAdaptiveWitnessDigest("code-947", title: "title-877")
        item.status = Consent.AdaptiveWitnessDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveWitnessDigestStatus.requested) }
    }
}
