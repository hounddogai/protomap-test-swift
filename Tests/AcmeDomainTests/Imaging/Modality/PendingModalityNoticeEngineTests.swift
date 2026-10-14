@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPendingModalityNoticeEngine()
        let item = Imaging.newPendingModalityNotice("code-502", title: "title-298")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
