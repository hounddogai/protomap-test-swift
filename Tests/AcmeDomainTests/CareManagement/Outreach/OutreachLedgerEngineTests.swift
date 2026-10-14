@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultOutreachLedgerEngine()
        let item = CareManagement.newOutreachLedger("code-700", label: "label-361")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
