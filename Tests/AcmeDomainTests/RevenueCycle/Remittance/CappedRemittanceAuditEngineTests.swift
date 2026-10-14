@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedRemittanceAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultCappedRemittanceAuditEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newCappedRemittanceAudit("code-881", label: "label-519")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
