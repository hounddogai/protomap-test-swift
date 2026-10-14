@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedDisclosureSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        #expect(item.status == Consent.WeightedDisclosureSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        try item.moveTo(Consent.WeightedDisclosureSnapshotStatus.validated)
        #expect(item.status == Consent.WeightedDisclosureSnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        item.status = Consent.WeightedDisclosureSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedDisclosureSnapshotStatus.created) }
    }
}
