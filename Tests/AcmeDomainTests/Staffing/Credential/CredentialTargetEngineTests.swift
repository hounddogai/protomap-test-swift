@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCredentialTargetEngine()
        let item = Staffing.newCredentialTarget("code-199", title: "title-29")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
