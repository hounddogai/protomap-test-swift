@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBundleTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newConsentFormBundle("code-116", name: "name-445")
        #expect(item.status == Consent.ConsentFormBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newConsentFormBundle("code-116", name: "name-445")
        try item.moveTo(Consent.ConsentFormBundleStatus.scheduled)
        #expect(item.status == Consent.ConsentFormBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newConsentFormBundle("code-116", name: "name-445")
        item.status = Consent.ConsentFormBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormBundleStatus.planned) }
    }
}
