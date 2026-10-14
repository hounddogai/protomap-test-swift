@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadWindowEngine()
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
