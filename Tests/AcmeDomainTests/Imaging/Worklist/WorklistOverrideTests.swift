@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistOverrideTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWorklistOverride("code-828", title: "title-857")
        #expect(item.status == Imaging.WorklistOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newWorklistOverride("code-828", title: "title-857")
        try item.moveTo(Imaging.WorklistOverrideStatus.expired)
        #expect(item.status == Imaging.WorklistOverrideStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWorklistOverride("code-828", title: "title-857")
        item.status = Imaging.WorklistOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistOverrideStatus.requested) }
    }
}
