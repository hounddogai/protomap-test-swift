@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPlanTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultSpecimenPlan("code-206", title: "title-674")
        #expect(item.status == Labs.DefaultSpecimenPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newDefaultSpecimenPlan("code-206", title: "title-674")
        try item.moveTo(Labs.DefaultSpecimenPlanStatus.withdrawn)
        #expect(item.status == Labs.DefaultSpecimenPlanStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultSpecimenPlan("code-206", title: "title-674")
        item.status = Labs.DefaultSpecimenPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenPlanStatus.proposed) }
    }
}
