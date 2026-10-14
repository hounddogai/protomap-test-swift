@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLenientFloatPoolVarianceEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLenientFloatPoolVariance("code-536", title: "title-404")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
