@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionNoticeTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        #expect(item.status == Pharmacy.PrimarySubstitutionNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        try item.moveTo(Pharmacy.PrimarySubstitutionNoticeStatus.approved)
        #expect(item.status == Pharmacy.PrimarySubstitutionNoticeStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        item.status = Pharmacy.PrimarySubstitutionNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionNoticeStatus.proposed) }
    }
}
