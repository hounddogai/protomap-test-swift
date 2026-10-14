@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultScheduledOutreachRequestEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
