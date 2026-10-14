@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyCareProtocolDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultLegacyCareProtocolDigestEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newLegacyCareProtocolDigest("code-7", title: "title-977")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
