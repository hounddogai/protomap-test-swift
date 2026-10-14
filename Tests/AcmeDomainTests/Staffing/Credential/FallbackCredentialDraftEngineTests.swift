@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackCredentialDraftEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
