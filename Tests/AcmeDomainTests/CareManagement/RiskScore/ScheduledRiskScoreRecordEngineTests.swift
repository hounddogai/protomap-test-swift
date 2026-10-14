@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultScheduledRiskScoreRecordEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newScheduledRiskScoreRecord("code-12", label: "label-545")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
