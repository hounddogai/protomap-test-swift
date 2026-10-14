@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRollingShiftManifestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRollingShiftManifest("code-511", name: "name-611")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
