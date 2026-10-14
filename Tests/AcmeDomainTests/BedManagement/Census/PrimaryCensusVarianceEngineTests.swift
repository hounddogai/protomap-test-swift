@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryCensusVarianceEngine()
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
