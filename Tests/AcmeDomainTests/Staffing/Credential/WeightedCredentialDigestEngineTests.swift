@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultWeightedCredentialDigestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newWeightedCredentialDigest("code-595", label: "label-22")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
