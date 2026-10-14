@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalWorklistOverrideTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newGlobalWorklistOverride("code-442", label: "label-831")
        #expect(item.status == Imaging.GlobalWorklistOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newGlobalWorklistOverride("code-442", label: "label-831")
        try item.moveTo(Imaging.GlobalWorklistOverrideStatus.validated)
        #expect(item.status == Imaging.GlobalWorklistOverrideStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newGlobalWorklistOverride("code-442", label: "label-831")
        item.status = Imaging.GlobalWorklistOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalWorklistOverrideStatus.created) }
    }
}
