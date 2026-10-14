@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultFallbackAccessionReservationEngine()
        let item = Labs.newFallbackAccessionReservation("code-338", title: "title-214")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
