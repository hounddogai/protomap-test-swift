@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAccessionBatchEngine()
        let item = Labs.newAccessionBatch("code-172", title: "title-862")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
