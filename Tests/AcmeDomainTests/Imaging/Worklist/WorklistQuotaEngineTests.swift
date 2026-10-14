@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWorklistQuotaEngine()
        let item = Imaging.newWorklistQuota("code-730", title: "title-495")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
