@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSlotTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        #expect(item.status == Imaging.WorklistSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        try item.moveTo(Imaging.WorklistSlotStatus.validated)
        #expect(item.status == Imaging.WorklistSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        item.status = Imaging.WorklistSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistSlotStatus.created) }
    }
}
