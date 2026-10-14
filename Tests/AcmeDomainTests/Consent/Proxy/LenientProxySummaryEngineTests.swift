@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxySummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientProxySummaryEngine()
        let item = Consent.newLenientProxySummary("code-906", name: "name-602")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
