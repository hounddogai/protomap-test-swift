@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyCycleEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
