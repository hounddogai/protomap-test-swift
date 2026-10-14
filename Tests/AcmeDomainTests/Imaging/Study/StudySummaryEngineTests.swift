@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudySummaryEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
