@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingDisclosureBudgetEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
