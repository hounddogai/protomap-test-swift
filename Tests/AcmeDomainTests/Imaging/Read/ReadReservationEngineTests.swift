@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadReservationEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadReservation("code-342", label: "label-456")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
