@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientBedBoardAllocationEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
