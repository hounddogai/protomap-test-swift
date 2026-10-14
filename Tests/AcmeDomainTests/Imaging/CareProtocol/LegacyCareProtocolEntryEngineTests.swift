@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLegacyCareProtocolEntryEngine()
        let item = Imaging.newLegacyCareProtocolEntry("code-931", label: "label-806")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
