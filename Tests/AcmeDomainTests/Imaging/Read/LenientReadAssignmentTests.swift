@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newLenientReadAssignment("code-135", name: "name-35")
        #expect(item.status == Imaging.LenientReadAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newLenientReadAssignment("code-135", name: "name-35")
        try item.moveTo(Imaging.LenientReadAssignmentStatus.suspended)
        #expect(item.status == Imaging.LenientReadAssignmentStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newLenientReadAssignment("code-135", name: "name-35")
        item.status = Imaging.LenientReadAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientReadAssignmentStatus.draft) }
    }
}
