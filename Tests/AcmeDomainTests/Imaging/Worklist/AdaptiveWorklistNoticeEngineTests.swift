@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultAdaptiveWorklistNoticeEngine()
        let item = Imaging.newAdaptiveWorklistNotice("code-526", title: "title-912")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
