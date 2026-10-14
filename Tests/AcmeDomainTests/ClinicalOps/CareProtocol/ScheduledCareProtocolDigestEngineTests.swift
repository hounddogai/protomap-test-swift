@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultScheduledCareProtocolDigestEngine()
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
