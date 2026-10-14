@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCredentialRollupEngine(Kit.Flags.newRegistry())
        let item = Staffing.newCredentialRollup("code-96", label: "label-438")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
