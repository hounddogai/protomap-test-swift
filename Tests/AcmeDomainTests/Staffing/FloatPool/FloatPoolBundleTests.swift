@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBundleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolBundle("code-151", label: "label-790")
        #expect(item.status == Staffing.FloatPoolBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Staffing.newFloatPoolBundle("code-151", label: "label-790")
        try item.moveTo(Staffing.FloatPoolBundleStatus.cancelled)
        #expect(item.status == Staffing.FloatPoolBundleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolBundle("code-151", label: "label-790")
        item.status = Staffing.FloatPoolBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolBundleStatus.planned) }
    }
}
