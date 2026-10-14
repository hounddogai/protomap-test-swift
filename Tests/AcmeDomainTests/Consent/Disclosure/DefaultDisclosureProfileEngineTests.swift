@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultDisclosureProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDefaultDisclosureProfileEngine(Kit.Flags.newRegistry())
        let item = Consent.newDefaultDisclosureProfile("code-725", label: "label-393")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
