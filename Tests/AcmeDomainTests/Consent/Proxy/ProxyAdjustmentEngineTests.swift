@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyAdjustment("code-949", label: "label-891")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
