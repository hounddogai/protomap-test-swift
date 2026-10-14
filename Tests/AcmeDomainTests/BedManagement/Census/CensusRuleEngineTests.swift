@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCensusRuleEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCensusRule("code-6", name: "name-435")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
