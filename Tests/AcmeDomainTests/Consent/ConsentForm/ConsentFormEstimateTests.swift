@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormEstimateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormEstimate("code-463", title: "title-797")
        #expect(item.status == Consent.ConsentFormEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newConsentFormEstimate("code-463", title: "title-797")
        try item.moveTo(Consent.ConsentFormEstimateStatus.granted)
        #expect(item.status == Consent.ConsentFormEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormEstimate("code-463", title: "title-797")
        item.status = Consent.ConsentFormEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormEstimateStatus.requested) }
    }
}
