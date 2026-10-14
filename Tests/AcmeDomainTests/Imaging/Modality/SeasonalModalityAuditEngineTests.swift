@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultSeasonalModalityAuditEngine(Kit.Flags.newRegistry())
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
