@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRegionalCredentialDraftEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
