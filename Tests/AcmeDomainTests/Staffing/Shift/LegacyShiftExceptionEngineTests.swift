@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLegacyShiftExceptionEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLegacyShiftException("code-464", name: "name-417")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
