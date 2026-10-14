@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLegacyCredentialScheduleEngine()
        let item = Staffing.newLegacyCredentialSchedule("code-392", label: "label-350")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
