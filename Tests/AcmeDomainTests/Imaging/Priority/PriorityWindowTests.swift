@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityWindowTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPriorityWindow("code-586", name: "name-45")
        #expect(item.status == Imaging.PriorityWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newPriorityWindow("code-586", name: "name-45")
        try item.moveTo(Imaging.PriorityWindowStatus.retired)
        #expect(item.status == Imaging.PriorityWindowStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPriorityWindow("code-586", name: "name-45")
        item.status = Imaging.PriorityWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityWindowStatus.created) }
    }
}
