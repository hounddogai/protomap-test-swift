@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultManualDischargePlanVarianceEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
