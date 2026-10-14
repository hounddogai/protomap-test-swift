@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionAssignment("code-783", title: "title-496")
        #expect(item.status == Pharmacy.SubstitutionAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newSubstitutionAssignment("code-783", title: "title-496")
        try item.moveTo(Pharmacy.SubstitutionAssignmentStatus.resolved)
        #expect(item.status == Pharmacy.SubstitutionAssignmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionAssignment("code-783", title: "title-496")
        item.status = Pharmacy.SubstitutionAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionAssignmentStatus.`open`) }
    }
}
