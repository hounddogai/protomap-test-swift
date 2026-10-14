@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCappedModalityDraftEngine(Kit.Flags.newRegistry())
        let item = Imaging.newCappedModalityDraft("code-299", label: "label-197")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
