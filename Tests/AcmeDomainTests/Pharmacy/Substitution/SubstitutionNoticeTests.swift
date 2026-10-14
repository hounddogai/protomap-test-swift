@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionNoticeTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newSubstitutionNotice("code-10", title: "title-183")
        #expect(item.status == Pharmacy.SubstitutionNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newSubstitutionNotice("code-10", title: "title-183")
        try item.moveTo(Pharmacy.SubstitutionNoticeStatus.retired)
        #expect(item.status == Pharmacy.SubstitutionNoticeStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newSubstitutionNotice("code-10", title: "title-183")
        item.status = Pharmacy.SubstitutionNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionNoticeStatus.created) }
    }
}
