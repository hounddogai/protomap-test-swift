@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyReservationEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
