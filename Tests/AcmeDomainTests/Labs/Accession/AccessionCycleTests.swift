@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCycleTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAccessionCycle("code-602", label: "label-850")
        #expect(item.status == Labs.AccessionCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newAccessionCycle("code-602", label: "label-850")
        try item.moveTo(Labs.AccessionCycleStatus.scheduled)
        #expect(item.status == Labs.AccessionCycleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAccessionCycle("code-602", label: "label-850")
        item.status = Labs.AccessionCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionCycleStatus.planned) }
    }
}
