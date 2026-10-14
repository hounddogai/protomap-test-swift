@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalModalityCycleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newGlobalModalityCycle("code-805", label: "label-478")
        #expect(item.status == Imaging.GlobalModalityCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newGlobalModalityCycle("code-805", label: "label-478")
        try item.moveTo(Imaging.GlobalModalityCycleStatus.queued)
        #expect(item.status == Imaging.GlobalModalityCycleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newGlobalModalityCycle("code-805", label: "label-478")
        item.status = Imaging.GlobalModalityCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalModalityCycleStatus.new) }
    }
}
