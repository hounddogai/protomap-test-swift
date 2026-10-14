@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultStrictHandoffReservationEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newStrictHandoffReservation("code-647", label: "label-646")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
