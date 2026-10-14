@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPendingCredentialLedgerEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
