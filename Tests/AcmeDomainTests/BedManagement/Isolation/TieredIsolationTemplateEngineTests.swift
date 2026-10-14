@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTieredIsolationTemplateEngine()
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
