@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveAuthorizationAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultAdaptiveAuthorizationAuditEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
