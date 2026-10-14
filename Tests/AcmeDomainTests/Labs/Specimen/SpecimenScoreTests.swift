@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScoreTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSpecimenScore("code-329", name: "name-965")
        #expect(item.status == Labs.SpecimenScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newSpecimenScore("code-329", name: "name-965")
        try item.moveTo(Labs.SpecimenScoreStatus.scheduled)
        #expect(item.status == Labs.SpecimenScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSpecimenScore("code-329", name: "name-965")
        item.status = Labs.SpecimenScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenScoreStatus.planned) }
    }
}
