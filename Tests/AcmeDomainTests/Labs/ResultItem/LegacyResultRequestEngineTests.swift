@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacyResultRequestEngine()
        let item = Labs.newLegacyResultRequest("code-593", title: "title-772")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
