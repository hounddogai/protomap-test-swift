@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityMilestone("code-850", label: "label-258")
        #expect(item.status == Imaging.ModalityMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newModalityMilestone("code-850", label: "label-258")
        try item.moveTo(Imaging.ModalityMilestoneStatus.scheduled)
        #expect(item.status == Imaging.ModalityMilestoneStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityMilestone("code-850", label: "label-258")
        item.status = Imaging.ModalityMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityMilestoneStatus.planned) }
    }
}
