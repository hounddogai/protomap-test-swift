@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityGroupTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newRollingPriorityGroup("code-100", title: "title-523")
        #expect(item.status == Imaging.RollingPriorityGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newRollingPriorityGroup("code-100", title: "title-523")
        try item.moveTo(Imaging.RollingPriorityGroupStatus.expired)
        #expect(item.status == Imaging.RollingPriorityGroupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newRollingPriorityGroup("code-100", title: "title-523")
        item.status = Imaging.RollingPriorityGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingPriorityGroupStatus.requested) }
    }
}
