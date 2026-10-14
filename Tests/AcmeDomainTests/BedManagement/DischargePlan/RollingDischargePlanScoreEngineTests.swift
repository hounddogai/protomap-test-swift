@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingDischargePlanScoreEngine()
        let item = BedManagement.newRollingDischargePlanScore("code-451", title: "title-363")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
