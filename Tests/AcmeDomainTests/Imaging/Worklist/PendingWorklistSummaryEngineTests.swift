@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPendingWorklistSummaryEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
