@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultFallbackLanguageBudgetEngine(Kit.Flags.newRegistry())
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
