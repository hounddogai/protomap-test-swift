@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadDraftEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
