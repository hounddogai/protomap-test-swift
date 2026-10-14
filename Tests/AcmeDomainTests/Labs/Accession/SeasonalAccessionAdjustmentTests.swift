@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSeasonalAccessionAdjustment("code-708", name: "name-760")
        #expect(item.status == Labs.SeasonalAccessionAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newSeasonalAccessionAdjustment("code-708", name: "name-760")
        try item.moveTo(Labs.SeasonalAccessionAdjustmentStatus.inProgress)
        #expect(item.status == Labs.SeasonalAccessionAdjustmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSeasonalAccessionAdjustment("code-708", name: "name-760")
        item.status = Labs.SeasonalAccessionAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalAccessionAdjustmentStatus.planned) }
    }
}
