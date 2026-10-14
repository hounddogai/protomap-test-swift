@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRegionalDisclosureSnapshot("code-613", title: "title-429")
        #expect(item.status == Consent.RegionalDisclosureSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newRegionalDisclosureSnapshot("code-613", title: "title-429")
        try item.moveTo(Consent.RegionalDisclosureSnapshotStatus.completed)
        #expect(item.status == Consent.RegionalDisclosureSnapshotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRegionalDisclosureSnapshot("code-613", title: "title-429")
        item.status = Consent.RegionalDisclosureSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalDisclosureSnapshotStatus.planned) }
    }
}
