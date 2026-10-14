@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultGlobalCensusRollupEngine()
        let item = BedManagement.newGlobalCensusRollup("code-421", name: "name-365")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
