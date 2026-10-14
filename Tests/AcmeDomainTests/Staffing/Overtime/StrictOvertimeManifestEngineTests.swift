@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultStrictOvertimeManifestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newStrictOvertimeManifest("code-323", name: "name-841")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
