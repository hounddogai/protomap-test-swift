@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newReadAssignment("code-867", name: "name-698")
        #expect(item.status == Imaging.ReadAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newReadAssignment("code-867", name: "name-698")
        try item.moveTo(Imaging.ReadAssignmentStatus.ready)
        #expect(item.status == Imaging.ReadAssignmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newReadAssignment("code-867", name: "name-698")
        item.status = Imaging.ReadAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadAssignmentStatus.idle) }
    }
}
