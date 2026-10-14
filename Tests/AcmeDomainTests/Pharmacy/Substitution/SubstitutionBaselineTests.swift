@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionBaselineTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newSubstitutionBaseline("code-688", title: "title-927")
        #expect(item.status == Pharmacy.SubstitutionBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newSubstitutionBaseline("code-688", title: "title-927")
        try item.moveTo(Pharmacy.SubstitutionBaselineStatus.published)
        #expect(item.status == Pharmacy.SubstitutionBaselineStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newSubstitutionBaseline("code-688", title: "title-927")
        item.status = Pharmacy.SubstitutionBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionBaselineStatus.created) }
    }
}
