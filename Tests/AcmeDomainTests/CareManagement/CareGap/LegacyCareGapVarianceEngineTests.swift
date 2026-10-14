@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLegacyCareGapVarianceEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
