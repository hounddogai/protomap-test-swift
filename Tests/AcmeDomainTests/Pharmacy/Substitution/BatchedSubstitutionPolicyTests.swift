@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionPolicyTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newBatchedSubstitutionPolicy("code-38", name: "name-215")
        #expect(item.status == Pharmacy.BatchedSubstitutionPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newBatchedSubstitutionPolicy("code-38", name: "name-215")
        try item.moveTo(Pharmacy.BatchedSubstitutionPolicyStatus.reopened)
        #expect(item.status == Pharmacy.BatchedSubstitutionPolicyStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newBatchedSubstitutionPolicy("code-38", name: "name-215")
        item.status = Pharmacy.BatchedSubstitutionPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedSubstitutionPolicyStatus.`open`) }
    }
}
