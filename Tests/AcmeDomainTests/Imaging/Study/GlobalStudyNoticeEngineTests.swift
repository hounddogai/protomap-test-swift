@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultGlobalStudyNoticeEngine()
        let item = Imaging.newGlobalStudyNotice("code-301", name: "name-118")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
