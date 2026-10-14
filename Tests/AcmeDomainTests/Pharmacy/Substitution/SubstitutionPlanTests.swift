@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPlanTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionPlan("code-929", name: "name-755")
        #expect(item.status == Pharmacy.SubstitutionPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newSubstitutionPlan("code-929", name: "name-755")
        try item.moveTo(Pharmacy.SubstitutionPlanStatus.resolved)
        #expect(item.status == Pharmacy.SubstitutionPlanStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionPlan("code-929", name: "name-755")
        item.status = Pharmacy.SubstitutionPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionPlanStatus.`open`) }
    }
}
