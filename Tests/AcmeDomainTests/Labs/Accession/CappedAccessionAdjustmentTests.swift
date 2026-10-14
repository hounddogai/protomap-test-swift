@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newCappedAccessionAdjustment("code-802", label: "label-90")
        #expect(item.status == Labs.CappedAccessionAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newCappedAccessionAdjustment("code-802", label: "label-90")
        try item.moveTo(Labs.CappedAccessionAdjustmentStatus.completed)
        #expect(item.status == Labs.CappedAccessionAdjustmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newCappedAccessionAdjustment("code-802", label: "label-90")
        item.status = Labs.CappedAccessionAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedAccessionAdjustmentStatus.planned) }
    }
}
