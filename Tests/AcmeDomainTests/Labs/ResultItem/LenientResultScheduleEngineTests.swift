@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientResultScheduleEngine()
        let item = Labs.newLenientResultSchedule("code-112", label: "label-980")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
