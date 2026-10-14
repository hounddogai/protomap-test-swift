@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelEstimateEngine()
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
