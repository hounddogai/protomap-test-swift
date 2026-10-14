@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelDigestEngine()
        let item = Labs.newPanelDigest("code-625", name: "name-179")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
