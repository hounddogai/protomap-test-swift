@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWitnessSummaryEngine(Kit.Flags.newRegistry())
        let item = Consent.newWitnessSummary("code-524", label: "label-686")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
