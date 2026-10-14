@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessDraftTests {
    @Test func startsInCreated() throws {
        let item = Consent.newManualWitnessDraft("code-723", title: "title-744")
        #expect(item.status == Consent.ManualWitnessDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newManualWitnessDraft("code-723", title: "title-744")
        try item.moveTo(Consent.ManualWitnessDraftStatus.published)
        #expect(item.status == Consent.ManualWitnessDraftStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newManualWitnessDraft("code-723", title: "title-744")
        item.status = Consent.ManualWitnessDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualWitnessDraftStatus.created) }
    }
}
