@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultManualOvertimeDigestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newManualOvertimeDigest("code-513", name: "name-222")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
