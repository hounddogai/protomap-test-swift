@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadGroupTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newReadGroup("code-71", name: "name-932")
        #expect(item.status == Imaging.ReadGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newReadGroup("code-71", name: "name-932")
        try item.moveTo(Imaging.ReadGroupStatus.approved)
        #expect(item.status == Imaging.ReadGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newReadGroup("code-71", name: "name-932")
        item.status = Imaging.ReadGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadGroupStatus.proposed) }
    }
}
