@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultScheduledCareProtocolProfileEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
