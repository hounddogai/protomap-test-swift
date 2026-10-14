@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalCredentialTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSeasonalCredentialTargetEngine(Kit.Flags.newRegistry())
        let item = Staffing.newSeasonalCredentialTarget("code-108", name: "name-465")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
