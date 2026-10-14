@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultOutreachTierEngine()
        let item = CareManagement.newOutreachTier("code-371", title: "title-271")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
