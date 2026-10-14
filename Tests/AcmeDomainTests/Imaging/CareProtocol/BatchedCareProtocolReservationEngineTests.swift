@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedCareProtocolReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultBatchedCareProtocolReservationEngine()
        let item = Imaging.newBatchedCareProtocolReservation("code-637", name: "name-223")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
