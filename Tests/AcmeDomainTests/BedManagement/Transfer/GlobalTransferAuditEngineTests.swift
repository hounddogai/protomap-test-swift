@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultGlobalTransferAuditEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newGlobalTransferAudit("code-667", name: "name-33")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
