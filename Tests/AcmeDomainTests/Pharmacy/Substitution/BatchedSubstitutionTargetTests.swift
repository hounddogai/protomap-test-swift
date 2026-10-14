@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newBatchedSubstitutionTarget("code-9", label: "label-680")
        #expect(item.status == Pharmacy.BatchedSubstitutionTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newBatchedSubstitutionTarget("code-9", label: "label-680")
        try item.moveTo(Pharmacy.BatchedSubstitutionTargetStatus.granted)
        #expect(item.status == Pharmacy.BatchedSubstitutionTargetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newBatchedSubstitutionTarget("code-9", label: "label-680")
        item.status = Pharmacy.BatchedSubstitutionTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedSubstitutionTargetStatus.requested) }
    }
}
