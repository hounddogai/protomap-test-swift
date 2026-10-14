@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultLenientCareProtocolManifestEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newLenientCareProtocolManifest("code-183", label: "label-792")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
