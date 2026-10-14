@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultSeasonalWorklistTemplateEngine(Kit.Flags.newRegistry())
        let item = Imaging.newSeasonalWorklistTemplate("code-735", title: "title-719")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
