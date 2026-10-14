@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPrimaryDisclosureRequestEngine(Kit.Flags.newRegistry())
        let item = Consent.newPrimaryDisclosureRequest("code-716", name: "name-108")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
