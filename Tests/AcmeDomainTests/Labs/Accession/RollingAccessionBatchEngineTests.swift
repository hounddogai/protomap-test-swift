@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingAccessionBatchEngine()
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
