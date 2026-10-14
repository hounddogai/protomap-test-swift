@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBundleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistBundle("code-259", label: "label-566")
        #expect(item.status == Imaging.WorklistBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistBundle("code-259", label: "label-566")
        try item.moveTo(Imaging.WorklistBundleStatus.validated)
        #expect(item.status == Imaging.WorklistBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistBundle("code-259", label: "label-566")
        item.status = Imaging.WorklistBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistBundleStatus.created) }
    }
}
