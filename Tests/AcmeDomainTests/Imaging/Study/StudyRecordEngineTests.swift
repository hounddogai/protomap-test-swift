@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudyRecordEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
