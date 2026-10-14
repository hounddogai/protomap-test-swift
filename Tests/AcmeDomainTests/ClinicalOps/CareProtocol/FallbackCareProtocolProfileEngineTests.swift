@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackCareProtocolProfileEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newFallbackCareProtocolProfile("code-684", name: "name-337")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
