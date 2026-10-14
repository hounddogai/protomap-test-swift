@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenPlanTests {
    @Test func startsInProposed() throws {
        let item = Labs.newStrictSpecimenPlan("code-543", label: "label-212")
        #expect(item.status == Labs.StrictSpecimenPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newStrictSpecimenPlan("code-543", label: "label-212")
        try item.moveTo(Labs.StrictSpecimenPlanStatus.approved)
        #expect(item.status == Labs.StrictSpecimenPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newStrictSpecimenPlan("code-543", label: "label-212")
        item.status = Labs.StrictSpecimenPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictSpecimenPlanStatus.proposed) }
    }
}
