@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultScheduledDispenseReservationEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newScheduledDispenseReservation("code-153", name: "name-549")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
