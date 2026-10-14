@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCareGapAuditEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
