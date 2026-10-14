@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDischargePlanAuditEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
