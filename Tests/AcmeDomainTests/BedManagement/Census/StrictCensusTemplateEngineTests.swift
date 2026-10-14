@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultStrictCensusTemplateEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newStrictCensusTemplate("code-139", title: "title-951")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
