@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredDisclosureGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredDisclosureGroupEngine(Kit.Flags.newRegistry())
        let item = Consent.newTieredDisclosureGroup("code-952", name: "name-625")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
