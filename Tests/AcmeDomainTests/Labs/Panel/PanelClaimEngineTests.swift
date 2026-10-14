@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelClaimEngine()
        let item = Labs.newPanelClaim("code-154", label: "label-218")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
