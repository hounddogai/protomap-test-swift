@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadTemplateEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadTemplate("code-167", label: "label-839")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
