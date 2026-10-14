@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPlanTests {
    @Test func startsInCreated() throws {
        let item = Labs.newSpecimenPlan("code-406", label: "label-157")
        #expect(item.status == Labs.SpecimenPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newSpecimenPlan("code-406", label: "label-157")
        try item.moveTo(Labs.SpecimenPlanStatus.validated)
        #expect(item.status == Labs.SpecimenPlanStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newSpecimenPlan("code-406", label: "label-157")
        item.status = Labs.SpecimenPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenPlanStatus.created) }
    }
}
