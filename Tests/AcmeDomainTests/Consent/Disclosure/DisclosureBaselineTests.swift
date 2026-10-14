@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBaselineTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDisclosureBaseline("code-122", label: "label-810")
        #expect(item.status == Consent.DisclosureBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newDisclosureBaseline("code-122", label: "label-810")
        try item.moveTo(Consent.DisclosureBaselineStatus.reopened)
        #expect(item.status == Consent.DisclosureBaselineStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDisclosureBaseline("code-122", label: "label-810")
        item.status = Consent.DisclosureBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureBaselineStatus.`open`) }
    }
}
