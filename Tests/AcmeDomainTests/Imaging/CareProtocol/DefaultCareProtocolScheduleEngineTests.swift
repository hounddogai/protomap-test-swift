@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultDefaultCareProtocolScheduleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newDefaultCareProtocolSchedule("code-656", title: "title-605")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
