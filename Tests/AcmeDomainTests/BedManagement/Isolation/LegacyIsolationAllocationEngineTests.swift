@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLegacyIsolationAllocationEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLegacyIsolationAllocation("code-402", title: "title-501")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
