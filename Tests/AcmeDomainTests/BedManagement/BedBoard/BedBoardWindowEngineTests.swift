@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBedBoardWindowEngine()
        let item = BedManagement.newBedBoardWindow("code-803", title: "title-348")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
