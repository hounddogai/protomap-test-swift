@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultBatchedOutreachPolicyEngine()
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
