@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistGroupTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistGroup("code-62", title: "title-615")
        #expect(item.status == Imaging.WorklistGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newWorklistGroup("code-62", title: "title-615")
        try item.moveTo(Imaging.WorklistGroupStatus.retired)
        #expect(item.status == Imaging.WorklistGroupStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistGroup("code-62", title: "title-615")
        item.status = Imaging.WorklistGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistGroupStatus.created) }
    }
}
