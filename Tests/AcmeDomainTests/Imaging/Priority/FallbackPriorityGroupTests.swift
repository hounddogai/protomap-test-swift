@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPriorityGroupTests {
    @Test func startsInNew() throws {
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        #expect(item.status == Imaging.FallbackPriorityGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        try item.moveTo(Imaging.FallbackPriorityGroupStatus.failed)
        #expect(item.status == Imaging.FallbackPriorityGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        item.status = Imaging.FallbackPriorityGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackPriorityGroupStatus.new) }
    }
}
