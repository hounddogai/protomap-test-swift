@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenOverrideTests {
    @Test func startsInDraft() throws {
        let item = Labs.newManualSpecimenOverride("code-118", label: "label-988")
        #expect(item.status == Labs.ManualSpecimenOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newManualSpecimenOverride("code-118", label: "label-988")
        try item.moveTo(Labs.ManualSpecimenOverrideStatus.pending)
        #expect(item.status == Labs.ManualSpecimenOverrideStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newManualSpecimenOverride("code-118", label: "label-988")
        item.status = Labs.ManualSpecimenOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualSpecimenOverrideStatus.draft) }
    }
}
