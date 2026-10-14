@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBudgetTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenBudget("code-283", label: "label-886")
        #expect(item.status == Labs.SpecimenBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newSpecimenBudget("code-283", label: "label-886")
        try item.moveTo(Labs.SpecimenBudgetStatus.warming)
        #expect(item.status == Labs.SpecimenBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenBudget("code-283", label: "label-886")
        item.status = Labs.SpecimenBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenBudgetStatus.idle) }
    }
}
