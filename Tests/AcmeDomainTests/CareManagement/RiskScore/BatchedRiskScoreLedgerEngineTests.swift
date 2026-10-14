@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultBatchedRiskScoreLedgerEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newBatchedRiskScoreLedger("code-897", label: "label-875")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
