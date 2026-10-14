@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultManualCensusLedgerEngine()
        let item = BedManagement.newManualCensusLedger("code-159", name: "name-252")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
