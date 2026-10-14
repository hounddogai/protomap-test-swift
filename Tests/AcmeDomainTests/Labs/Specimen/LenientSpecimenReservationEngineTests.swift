@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientSpecimenReservationEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
