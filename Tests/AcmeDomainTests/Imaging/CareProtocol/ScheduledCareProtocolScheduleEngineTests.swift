@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultScheduledCareProtocolScheduleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
