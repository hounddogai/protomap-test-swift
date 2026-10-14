@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalityGroupEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalityGroup("code-873", label: "label-637")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
