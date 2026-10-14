@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalityBaselineEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalityBaseline("code-408", label: "label-517")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
