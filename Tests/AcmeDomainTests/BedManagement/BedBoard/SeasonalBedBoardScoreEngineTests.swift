@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalBedBoardScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultSeasonalBedBoardScoreEngine()
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
