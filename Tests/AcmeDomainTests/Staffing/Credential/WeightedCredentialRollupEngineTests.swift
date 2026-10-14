@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultWeightedCredentialRollupEngine(Kit.Flags.newRegistry())
        let item = Staffing.newWeightedCredentialRollup("code-652", label: "label-354")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
