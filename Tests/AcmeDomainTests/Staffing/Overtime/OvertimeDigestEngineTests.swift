@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultOvertimeDigestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newOvertimeDigest("code-393", title: "title-884")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
