@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultCappedRecallReservationEngine()
        let item = Pharmacy.newCappedRecallReservation("code-817", name: "name-698")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
