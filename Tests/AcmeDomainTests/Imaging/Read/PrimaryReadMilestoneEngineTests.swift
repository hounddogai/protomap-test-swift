@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryReadMilestoneEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
