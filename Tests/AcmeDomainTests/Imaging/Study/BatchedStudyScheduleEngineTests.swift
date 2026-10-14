@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudyScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultBatchedStudyScheduleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newBatchedStudySchedule("code-151", name: "name-961")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
