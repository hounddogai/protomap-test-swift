@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureSnapshotTests {
    @Test func startsInOpen() throws {
        let item = Consent.newGlobalDisclosureSnapshot("code-218", label: "label-216")
        #expect(item.status == Consent.GlobalDisclosureSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newGlobalDisclosureSnapshot("code-218", label: "label-216")
        try item.moveTo(Consent.GlobalDisclosureSnapshotStatus.inReview)
        #expect(item.status == Consent.GlobalDisclosureSnapshotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newGlobalDisclosureSnapshot("code-218", label: "label-216")
        item.status = Consent.GlobalDisclosureSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalDisclosureSnapshotStatus.`open`) }
    }
}
