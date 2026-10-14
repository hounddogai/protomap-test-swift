@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryWorklistNoticeEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryWorklistNotice("code-765", label: "label-345")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
