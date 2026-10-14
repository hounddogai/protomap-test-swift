@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFloatPoolPreference("code-943", name: "name-228")
        #expect(item.status == Staffing.FloatPoolPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newFloatPoolPreference("code-943", name: "name-228")
        try item.moveTo(Staffing.FloatPoolPreferenceStatus.warming)
        #expect(item.status == Staffing.FloatPoolPreferenceStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFloatPoolPreference("code-943", name: "name-228")
        item.status = Staffing.FloatPoolPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolPreferenceStatus.idle) }
    }
}
