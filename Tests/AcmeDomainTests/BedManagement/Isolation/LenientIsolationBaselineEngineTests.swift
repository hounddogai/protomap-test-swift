@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientIsolationBaselineEngine()
        let item = BedManagement.newLenientIsolationBaseline("code-43", label: "label-106")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
