@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPriorityGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultFallbackPriorityGroupEngine(Kit.Flags.newRegistry())
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
