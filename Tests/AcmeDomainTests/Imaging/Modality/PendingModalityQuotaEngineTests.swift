@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPendingModalityQuotaEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
