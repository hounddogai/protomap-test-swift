@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPrimaryAssessmentAuditEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPrimaryAssessmentAudit("code-845", name: "name-473")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
