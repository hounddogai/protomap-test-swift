@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLegacyProxyTemplateEngine(Kit.Flags.newRegistry())
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
