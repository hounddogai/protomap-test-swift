@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultFallbackCleaningEntryEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newFallbackCleaningEntry("code-730", name: "name-47")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
