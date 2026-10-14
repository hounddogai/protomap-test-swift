@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualCareProtocolBundleEngine()
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
