@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryReadReservationEngine()
        let item = Imaging.newPrimaryReadReservation("code-711", title: "title-934")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
