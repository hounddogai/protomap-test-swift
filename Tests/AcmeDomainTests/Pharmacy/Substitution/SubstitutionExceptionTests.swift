@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionExceptionTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionException("code-510", title: "title-39")
        #expect(item.status == Pharmacy.SubstitutionExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newSubstitutionException("code-510", title: "title-39")
        try item.moveTo(Pharmacy.SubstitutionExceptionStatus.reopened)
        #expect(item.status == Pharmacy.SubstitutionExceptionStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionException("code-510", title: "title-39")
        item.status = Pharmacy.SubstitutionExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionExceptionStatus.`open`) }
    }
}
