@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultWeightedIsolationEntryEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newWeightedIsolationEntry("code-139", label: "label-349")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
