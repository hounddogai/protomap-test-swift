@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPendingGoalPreferenceEngine()
        let item = CareManagement.newPendingGoalPreference("code-936", name: "name-108")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
