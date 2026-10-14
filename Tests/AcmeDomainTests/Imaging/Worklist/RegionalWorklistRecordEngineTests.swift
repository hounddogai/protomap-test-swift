@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalWorklistRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRegionalWorklistRecordEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRegionalWorklistRecord("code-25", label: "label-134")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
