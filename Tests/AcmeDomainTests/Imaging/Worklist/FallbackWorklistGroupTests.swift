@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistGroupTests {
    @Test func startsInNew() throws {
        let item = Imaging.newFallbackWorklistGroup("code-169", name: "name-712")
        #expect(item.status == Imaging.FallbackWorklistGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newFallbackWorklistGroup("code-169", name: "name-712")
        try item.moveTo(Imaging.FallbackWorklistGroupStatus.failed)
        #expect(item.status == Imaging.FallbackWorklistGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newFallbackWorklistGroup("code-169", name: "name-712")
        item.status = Imaging.FallbackWorklistGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackWorklistGroupStatus.new) }
    }
}
