@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLenientOutreachAuditEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
