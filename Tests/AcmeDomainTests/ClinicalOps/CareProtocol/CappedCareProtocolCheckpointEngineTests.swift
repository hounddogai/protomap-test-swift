@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultCappedCareProtocolCheckpointEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("code-321", title: "title-468")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
