@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPendingProgramEstimateEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPendingProgramEstimate("code-196", name: "name-761")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
