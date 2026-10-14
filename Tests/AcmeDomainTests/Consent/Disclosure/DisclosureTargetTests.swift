@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTargetTests {
    @Test func startsInDraft() throws {
        let item = Consent.newDisclosureTarget("code-863", title: "title-886")
        #expect(item.status == Consent.DisclosureTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newDisclosureTarget("code-863", title: "title-886")
        try item.moveTo(Consent.DisclosureTargetStatus.active)
        #expect(item.status == Consent.DisclosureTargetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newDisclosureTarget("code-863", title: "title-886")
        item.status = Consent.DisclosureTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureTargetStatus.draft) }
    }
}
