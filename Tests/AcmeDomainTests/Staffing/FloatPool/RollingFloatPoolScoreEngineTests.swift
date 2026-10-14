@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingFloatPoolScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRollingFloatPoolScoreEngine()
        let item = Staffing.newRollingFloatPoolScore("code-842", label: "label-889")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
