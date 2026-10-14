@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRollupTests {
    @Test func startsInDraft() throws {
        let item = Consent.newDisclosureRollup("code-263", name: "name-268")
        #expect(item.status == Consent.DisclosureRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newDisclosureRollup("code-263", name: "name-268")
        try item.moveTo(Consent.DisclosureRollupStatus.pending)
        #expect(item.status == Consent.DisclosureRollupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newDisclosureRollup("code-263", name: "name-268")
        item.status = Consent.DisclosureRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureRollupStatus.draft) }
    }
}
