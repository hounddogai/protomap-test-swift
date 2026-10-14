@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultIsolationPolicyEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
