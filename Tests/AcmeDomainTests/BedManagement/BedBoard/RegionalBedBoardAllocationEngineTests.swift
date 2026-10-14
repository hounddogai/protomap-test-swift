@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalBedBoardAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRegionalBedBoardAllocationEngine()
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
