@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStrictCareProtocolTemplateEngine()
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
