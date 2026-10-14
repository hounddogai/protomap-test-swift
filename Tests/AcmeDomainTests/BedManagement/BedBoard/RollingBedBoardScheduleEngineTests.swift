@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingBedBoardScheduleEngine()
        let item = BedManagement.newRollingBedBoardSchedule("code-41", label: "label-815")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
