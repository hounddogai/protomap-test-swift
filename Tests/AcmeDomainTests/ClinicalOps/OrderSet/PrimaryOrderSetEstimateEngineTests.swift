@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultPrimaryOrderSetEstimateEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
