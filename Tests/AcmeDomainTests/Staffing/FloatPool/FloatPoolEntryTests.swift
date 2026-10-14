@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEntryTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newFloatPoolEntry("code-583", name: "name-975")
        #expect(item.status == Staffing.FloatPoolEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newFloatPoolEntry("code-583", name: "name-975")
        try item.moveTo(Staffing.FloatPoolEntryStatus.granted)
        #expect(item.status == Staffing.FloatPoolEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newFloatPoolEntry("code-583", name: "name-975")
        item.status = Staffing.FloatPoolEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolEntryStatus.requested) }
    }
}
