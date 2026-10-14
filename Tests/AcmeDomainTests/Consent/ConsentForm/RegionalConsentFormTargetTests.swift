@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormTargetTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRegionalConsentFormTarget("code-886", title: "title-485")
        #expect(item.status == Consent.RegionalConsentFormTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newRegionalConsentFormTarget("code-886", title: "title-485")
        try item.moveTo(Consent.RegionalConsentFormTargetStatus.inProgress)
        #expect(item.status == Consent.RegionalConsentFormTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRegionalConsentFormTarget("code-886", title: "title-485")
        item.status = Consent.RegionalConsentFormTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalConsentFormTargetStatus.planned) }
    }
}
