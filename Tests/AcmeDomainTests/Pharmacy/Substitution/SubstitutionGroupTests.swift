@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionGroupTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newSubstitutionGroup("code-803", name: "name-143")
        #expect(item.status == Pharmacy.SubstitutionGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newSubstitutionGroup("code-803", name: "name-143")
        try item.moveTo(Pharmacy.SubstitutionGroupStatus.expired)
        #expect(item.status == Pharmacy.SubstitutionGroupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newSubstitutionGroup("code-803", name: "name-143")
        item.status = Pharmacy.SubstitutionGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionGroupStatus.requested) }
    }
}
