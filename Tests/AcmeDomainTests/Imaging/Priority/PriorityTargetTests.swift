@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTargetTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPriorityTarget("code-638", label: "label-518")
        #expect(item.status == Imaging.PriorityTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newPriorityTarget("code-638", label: "label-518")
        try item.moveTo(Imaging.PriorityTargetStatus.scheduled)
        #expect(item.status == Imaging.PriorityTargetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPriorityTarget("code-638", label: "label-518")
        item.status = Imaging.PriorityTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityTargetStatus.planned) }
    }
}
