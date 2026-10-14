@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDisclosureRollupEngine(Kit.Flags.newRegistry())
        let item = Consent.newDisclosureRollup("code-263", name: "name-268")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
