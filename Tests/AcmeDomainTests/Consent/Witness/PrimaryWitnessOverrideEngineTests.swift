@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryWitnessOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPrimaryWitnessOverrideEngine(Kit.Flags.newRegistry())
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
