@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryProxySummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPrimaryProxySummaryEngine(Kit.Flags.newRegistry())
        let item = Consent.newPrimaryProxySummary("code-241", name: "name-994")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
