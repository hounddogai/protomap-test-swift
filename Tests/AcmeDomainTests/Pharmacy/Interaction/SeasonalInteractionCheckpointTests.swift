@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSeasonalInteractionCheckpoint("code-908", name: "name-349")
        #expect(item.status == Pharmacy.SeasonalInteractionCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newSeasonalInteractionCheckpoint("code-908", name: "name-349")
        try item.moveTo(Pharmacy.SeasonalInteractionCheckpointStatus.suspended)
        #expect(item.status == Pharmacy.SeasonalInteractionCheckpointStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSeasonalInteractionCheckpoint("code-908", name: "name-349")
        item.status = Pharmacy.SeasonalInteractionCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInteractionCheckpointStatus.draft) }
    }
}
