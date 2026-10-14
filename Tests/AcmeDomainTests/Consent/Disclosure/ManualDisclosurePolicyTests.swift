@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualDisclosurePolicyTests {
    @Test func startsInOpen() throws {
        let item = Consent.newManualDisclosurePolicy("code-129", title: "title-739")
        #expect(item.status == Consent.ManualDisclosurePolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newManualDisclosurePolicy("code-129", title: "title-739")
        try item.moveTo(Consent.ManualDisclosurePolicyStatus.archived)
        #expect(item.status == Consent.ManualDisclosurePolicyStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newManualDisclosurePolicy("code-129", title: "title-739")
        item.status = Consent.ManualDisclosurePolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualDisclosurePolicyStatus.`open`) }
    }
}
