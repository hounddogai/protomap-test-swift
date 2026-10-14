@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultScheduledCensusAgreementEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newScheduledCensusAgreement("code-895", name: "name-920")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
