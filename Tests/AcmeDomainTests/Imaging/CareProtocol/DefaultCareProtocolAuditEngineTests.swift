@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultDefaultCareProtocolAuditEngine()
        let item = Imaging.newDefaultCareProtocolAudit("code-821", title: "title-470")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
