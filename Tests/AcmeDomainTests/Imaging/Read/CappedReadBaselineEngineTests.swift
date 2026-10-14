@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedReadBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCappedReadBaselineEngine(Kit.Flags.newRegistry())
        let item = Imaging.newCappedReadBaseline("code-909", name: "name-224")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
