@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedOutreachTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCappedOutreachTemplateEngine()
        let item = CareManagement.newCappedOutreachTemplate("code-105", label: "label-433")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
