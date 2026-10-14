@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultConsentFormCycleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDefaultConsentFormCycle("code-713", title: "title-289")
        #expect(item.status == Consent.DefaultConsentFormCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newDefaultConsentFormCycle("code-713", title: "title-289")
        try item.moveTo(Consent.DefaultConsentFormCycleStatus.resolved)
        #expect(item.status == Consent.DefaultConsentFormCycleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDefaultConsentFormCycle("code-713", title: "title-289")
        item.status = Consent.DefaultConsentFormCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultConsentFormCycleStatus.`open`) }
    }
}
