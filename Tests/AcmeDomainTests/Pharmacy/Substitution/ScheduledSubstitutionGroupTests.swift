@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledSubstitutionGroupTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newScheduledSubstitutionGroup("code-244", title: "title-520")
        #expect(item.status == Pharmacy.ScheduledSubstitutionGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newScheduledSubstitutionGroup("code-244", title: "title-520")
        try item.moveTo(Pharmacy.ScheduledSubstitutionGroupStatus.validated)
        #expect(item.status == Pharmacy.ScheduledSubstitutionGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newScheduledSubstitutionGroup("code-244", title: "title-520")
        item.status = Pharmacy.ScheduledSubstitutionGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledSubstitutionGroupStatus.created) }
    }
}
