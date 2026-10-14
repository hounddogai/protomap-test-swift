@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCycleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newSpecimenCycle("code-471", name: "name-263")
        #expect(item.status == Labs.SpecimenCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newSpecimenCycle("code-471", name: "name-263")
        try item.moveTo(Labs.SpecimenCycleStatus.published)
        #expect(item.status == Labs.SpecimenCycleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newSpecimenCycle("code-471", name: "name-263")
        item.status = Labs.SpecimenCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenCycleStatus.created) }
    }
}
