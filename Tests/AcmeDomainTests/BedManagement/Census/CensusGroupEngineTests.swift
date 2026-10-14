@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCensusGroupEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCensusGroup("code-542", title: "title-286")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
