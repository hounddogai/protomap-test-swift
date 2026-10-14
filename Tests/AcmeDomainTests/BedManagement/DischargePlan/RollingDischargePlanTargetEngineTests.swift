@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingDischargePlanTargetEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newRollingDischargePlanTarget("code-21", title: "title-899")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
