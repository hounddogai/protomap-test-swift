@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistWindowTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistWindow("code-473", title: "title-104")
        #expect(item.status == Imaging.WorklistWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistWindow("code-473", title: "title-104")
        try item.moveTo(Imaging.WorklistWindowStatus.validated)
        #expect(item.status == Imaging.WorklistWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistWindow("code-473", title: "title-104")
        item.status = Imaging.WorklistWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistWindowStatus.created) }
    }
}
