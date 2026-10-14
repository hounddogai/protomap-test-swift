@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPriorityTemplateEngine()
        let item = Imaging.newPriorityTemplate("code-355", label: "label-553")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
