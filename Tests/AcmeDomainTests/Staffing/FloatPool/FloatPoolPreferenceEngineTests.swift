@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFloatPoolPreferenceEngine()
        let item = Staffing.newFloatPoolPreference("code-943", name: "name-228")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
