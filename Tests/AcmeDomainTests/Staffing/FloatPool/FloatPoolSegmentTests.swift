@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolSegmentTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolSegment("code-739", title: "title-46")
        #expect(item.status == Staffing.FloatPoolSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newFloatPoolSegment("code-739", title: "title-46")
        try item.moveTo(Staffing.FloatPoolSegmentStatus.inProgress)
        #expect(item.status == Staffing.FloatPoolSegmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolSegment("code-739", title: "title-46")
        item.status = Staffing.FloatPoolSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolSegmentStatus.planned) }
    }
}
