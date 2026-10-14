@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureOverrideTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDisclosureOverride("code-660", label: "label-345")
        #expect(item.status == Consent.DisclosureOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newDisclosureOverride("code-660", label: "label-345")
        try item.moveTo(Consent.DisclosureOverrideStatus.archived)
        #expect(item.status == Consent.DisclosureOverrideStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDisclosureOverride("code-660", label: "label-345")
        item.status = Consent.DisclosureOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureOverrideStatus.`open`) }
    }
}
