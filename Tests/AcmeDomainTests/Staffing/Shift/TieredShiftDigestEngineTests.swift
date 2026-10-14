@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultTieredShiftDigestEngine()
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
