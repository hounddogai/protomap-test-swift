@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierThresholdEngine()
        let item = Labs.newCourierThreshold("code-849", name: "name-859")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
