@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPendingReadReservationEngine()
        let item = Imaging.newPendingReadReservation("code-781", label: "label-138")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
