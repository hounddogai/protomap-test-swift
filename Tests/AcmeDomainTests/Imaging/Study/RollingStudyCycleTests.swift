@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyCycleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRollingStudyCycle("code-649", title: "title-821")
        #expect(item.status == Imaging.RollingStudyCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newRollingStudyCycle("code-649", title: "title-821")
        try item.moveTo(Imaging.RollingStudyCycleStatus.queued)
        #expect(item.status == Imaging.RollingStudyCycleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRollingStudyCycle("code-649", title: "title-821")
        item.status = Imaging.RollingStudyCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingStudyCycleStatus.new) }
    }
}
