@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimaryShiftPreferenceEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
