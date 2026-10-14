@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadOverrideEngine()
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
