@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPendingCredentialRequestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPendingCredentialRequest("code-789", title: "title-547")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
