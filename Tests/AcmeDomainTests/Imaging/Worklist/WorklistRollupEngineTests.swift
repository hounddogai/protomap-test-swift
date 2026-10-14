@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWorklistRollupEngine(Kit.Flags.newRegistry())
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
