@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackProgramVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultFallbackProgramVarianceEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
