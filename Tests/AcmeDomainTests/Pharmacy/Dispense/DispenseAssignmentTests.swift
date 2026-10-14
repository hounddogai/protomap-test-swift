@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseAssignment("code-231", label: "label-283")
        #expect(item.status == Pharmacy.DispenseAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newDispenseAssignment("code-231", label: "label-283")
        try item.moveTo(Pharmacy.DispenseAssignmentStatus.pending)
        #expect(item.status == Pharmacy.DispenseAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseAssignment("code-231", label: "label-283")
        item.status = Pharmacy.DispenseAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseAssignmentStatus.draft) }
    }
}
