@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRequestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSubstitutionRequest("code-911", title: "title-527")
        #expect(item.status == Pharmacy.SubstitutionRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newSubstitutionRequest("code-911", title: "title-527")
        try item.moveTo(Pharmacy.SubstitutionRequestStatus.pending)
        #expect(item.status == Pharmacy.SubstitutionRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSubstitutionRequest("code-911", title: "title-527")
        item.status = Pharmacy.SubstitutionRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionRequestStatus.draft) }
    }
}
