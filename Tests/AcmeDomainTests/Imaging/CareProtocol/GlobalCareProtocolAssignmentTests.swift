@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newGlobalCareProtocolAssignment("code-590", title: "title-258")
        #expect(item.status == Imaging.GlobalCareProtocolAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newGlobalCareProtocolAssignment("code-590", title: "title-258")
        try item.moveTo(Imaging.GlobalCareProtocolAssignmentStatus.ready)
        #expect(item.status == Imaging.GlobalCareProtocolAssignmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newGlobalCareProtocolAssignment("code-590", title: "title-258")
        item.status = Imaging.GlobalCareProtocolAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalCareProtocolAssignmentStatus.idle) }
    }
}
