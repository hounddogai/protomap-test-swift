@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenAdjustment("code-801", label: "label-272")
        #expect(item.status == Labs.SpecimenAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newSpecimenAdjustment("code-801", label: "label-272")
        try item.moveTo(Labs.SpecimenAdjustmentStatus.pending)
        #expect(item.status == Labs.SpecimenAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenAdjustment("code-801", label: "label-272")
        item.status = Labs.SpecimenAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenAdjustmentStatus.draft) }
    }
}
