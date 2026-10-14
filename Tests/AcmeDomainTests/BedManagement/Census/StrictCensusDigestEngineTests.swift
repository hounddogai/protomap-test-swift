@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultStrictCensusDigestEngine()
        let item = BedManagement.newStrictCensusDigest("code-460", title: "title-586")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
