@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictDischargePlanPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultStrictDischargePlanPolicyEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
