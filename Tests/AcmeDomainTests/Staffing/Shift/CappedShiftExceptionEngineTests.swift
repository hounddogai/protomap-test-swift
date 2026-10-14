@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCappedShiftExceptionEngine()
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
