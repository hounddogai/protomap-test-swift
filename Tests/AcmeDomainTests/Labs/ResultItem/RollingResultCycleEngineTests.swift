@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingResultCycleEngine()
        let item = Labs.newRollingResultCycle("code-51", title: "title-472")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
