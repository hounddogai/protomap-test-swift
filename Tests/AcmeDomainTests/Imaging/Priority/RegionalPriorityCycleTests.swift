@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityCycleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        #expect(item.status == Imaging.RegionalPriorityCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        try item.moveTo(Imaging.RegionalPriorityCycleStatus.completed)
        #expect(item.status == Imaging.RegionalPriorityCycleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        item.status = Imaging.RegionalPriorityCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalPriorityCycleStatus.planned) }
    }
}
