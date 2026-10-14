@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRollingOvertimeDraftEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRollingOvertimeDraft("code-870", label: "label-947")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
