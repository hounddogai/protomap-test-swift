@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenCycleTests {
    @Test func startsInNew() throws {
        let item = Labs.newCappedSpecimenCycle("code-408", title: "title-565")
        #expect(item.status == Labs.CappedSpecimenCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newCappedSpecimenCycle("code-408", title: "title-565")
        try item.moveTo(Labs.CappedSpecimenCycleStatus.done)
        #expect(item.status == Labs.CappedSpecimenCycleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCappedSpecimenCycle("code-408", title: "title-565")
        item.status = Labs.CappedSpecimenCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedSpecimenCycleStatus.new) }
    }
}
