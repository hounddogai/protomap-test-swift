@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBedBoardScoreEngine()
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
