@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingIsolationTemplateEngine()
        let item = BedManagement.newRollingIsolationTemplate("code-887", label: "label-852")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
