@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultSeasonalWitnessBudgetEngine(Kit.Flags.newRegistry())
        let item = Consent.newSeasonalWitnessBudget("code-379", title: "title-736")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
