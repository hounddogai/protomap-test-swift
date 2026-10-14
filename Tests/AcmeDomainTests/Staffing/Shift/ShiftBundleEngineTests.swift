@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultShiftBundleEngine()
        let item = Staffing.newShiftBundle("code-583", name: "name-194")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
