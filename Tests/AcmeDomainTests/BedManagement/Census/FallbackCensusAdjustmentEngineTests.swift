@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultFallbackCensusAdjustmentEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
