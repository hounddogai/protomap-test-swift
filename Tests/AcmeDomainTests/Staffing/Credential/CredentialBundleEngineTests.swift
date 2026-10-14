@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCredentialBundleEngine()
        let item = Staffing.newCredentialBundle("code-885", name: "name-614")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
