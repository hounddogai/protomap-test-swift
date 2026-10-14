@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newReadMilestone("code-469", name: "name-117")
        #expect(item.status == Imaging.ReadMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newReadMilestone("code-469", name: "name-117")
        try item.moveTo(Imaging.ReadMilestoneStatus.completed)
        #expect(item.status == Imaging.ReadMilestoneStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newReadMilestone("code-469", name: "name-117")
        item.status = Imaging.ReadMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadMilestoneStatus.planned) }
    }
}
