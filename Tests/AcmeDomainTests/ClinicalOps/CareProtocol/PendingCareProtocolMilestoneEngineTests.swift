@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingCareProtocolMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultPendingCareProtocolMilestoneEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
