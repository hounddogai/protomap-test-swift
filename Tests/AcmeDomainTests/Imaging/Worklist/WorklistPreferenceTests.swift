@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistPreference("code-186", title: "title-77")
        #expect(item.status == Imaging.WorklistPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newWorklistPreference("code-186", title: "title-77")
        try item.moveTo(Imaging.WorklistPreferenceStatus.approved)
        #expect(item.status == Imaging.WorklistPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistPreference("code-186", title: "title-77")
        item.status = Imaging.WorklistPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistPreferenceStatus.proposed) }
    }
}
