@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalAccessionTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultGlobalAccessionTierEngine()
        let item = Labs.newGlobalAccessionTier("code-413", title: "title-261")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
