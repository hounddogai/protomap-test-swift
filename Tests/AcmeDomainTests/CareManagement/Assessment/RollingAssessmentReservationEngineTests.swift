@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingAssessmentReservationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingAssessmentReservation("code-70", name: "name-440")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
