@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultFallbackCensusBundleEngine()
        let item = BedManagement.newFallbackCensusBundle("code-209", name: "name-718")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
