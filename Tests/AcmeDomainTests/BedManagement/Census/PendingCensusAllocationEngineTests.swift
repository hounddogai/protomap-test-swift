@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPendingCensusAllocationEngine()
        let item = BedManagement.newPendingCensusAllocation("code-575", title: "title-421")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
