@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredProxyCycleEngine(Kit.Flags.newRegistry())
        let item = Consent.newTieredProxyCycle("code-206", name: "name-590")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
