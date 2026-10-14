@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredCredentialPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultTieredCredentialPolicyEngine(Kit.Flags.newRegistry())
        let item = Staffing.newTieredCredentialPolicy("code-433", name: "name-695")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
