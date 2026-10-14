@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierBatchEngine()
        let item = Labs.newCourierBatch("code-416", label: "label-450")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
