@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveDischargePlanBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultAdaptiveDischargePlanBaselineEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newAdaptiveDischargePlanBaseline("code-921", name: "name-222")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
