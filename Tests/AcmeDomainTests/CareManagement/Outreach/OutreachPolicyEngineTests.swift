@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultOutreachPolicyEngine()
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
