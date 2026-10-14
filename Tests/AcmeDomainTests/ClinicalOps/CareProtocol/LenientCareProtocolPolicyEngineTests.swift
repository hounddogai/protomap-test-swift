@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultLenientCareProtocolPolicyEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newLenientCareProtocolPolicy("code-321", title: "title-615")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
