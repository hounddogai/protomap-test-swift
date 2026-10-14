@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCensusDigestEngine()
        let item = BedManagement.newCensusDigest("code-781", title: "title-982")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
