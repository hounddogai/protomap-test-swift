@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityGroupTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        #expect(item.status == Imaging.PriorityGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        try item.moveTo(Imaging.PriorityGroupStatus.granted)
        #expect(item.status == Imaging.PriorityGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        item.status = Imaging.PriorityGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityGroupStatus.requested) }
    }
}
