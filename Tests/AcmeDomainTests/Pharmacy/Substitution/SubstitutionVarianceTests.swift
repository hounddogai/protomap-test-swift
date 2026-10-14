@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionVarianceTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSubstitutionVariance("code-750", label: "label-432")
        #expect(item.status == Pharmacy.SubstitutionVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Pharmacy.newSubstitutionVariance("code-750", label: "label-432")
        try item.moveTo(Pharmacy.SubstitutionVarianceStatus.closed)
        #expect(item.status == Pharmacy.SubstitutionVarianceStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSubstitutionVariance("code-750", label: "label-432")
        item.status = Pharmacy.SubstitutionVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionVarianceStatus.draft) }
    }
}
