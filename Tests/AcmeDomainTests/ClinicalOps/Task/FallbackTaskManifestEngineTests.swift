@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackTaskManifestEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newFallbackTaskManifest("code-655", name: "name-975")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
