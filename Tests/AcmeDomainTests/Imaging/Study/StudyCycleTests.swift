@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyCycleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStudyCycle("code-988", label: "label-288")
        #expect(item.status == Imaging.StudyCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newStudyCycle("code-988", label: "label-288")
        try item.moveTo(Imaging.StudyCycleStatus.scheduled)
        #expect(item.status == Imaging.StudyCycleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStudyCycle("code-988", label: "label-288")
        item.status = Imaging.StudyCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyCycleStatus.planned) }
    }
}
