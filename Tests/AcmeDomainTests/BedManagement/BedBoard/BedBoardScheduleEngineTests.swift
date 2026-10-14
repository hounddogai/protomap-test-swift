@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBedBoardScheduleEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBedBoardSchedule("code-49", name: "name-589")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
