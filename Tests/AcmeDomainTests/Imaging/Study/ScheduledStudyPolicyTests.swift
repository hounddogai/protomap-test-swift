@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        #expect(item.status == Imaging.ScheduledStudyPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        try item.moveTo(Imaging.ScheduledStudyPolicyStatus.cancelled)
        #expect(item.status == Imaging.ScheduledStudyPolicyStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        item.status = Imaging.ScheduledStudyPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledStudyPolicyStatus.planned) }
    }
}
