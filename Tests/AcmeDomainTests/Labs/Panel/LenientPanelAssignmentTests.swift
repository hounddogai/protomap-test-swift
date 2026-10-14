@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientPanelAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Labs.newLenientPanelAssignment("code-476", name: "name-816")
        #expect(item.status == Labs.LenientPanelAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newLenientPanelAssignment("code-476", name: "name-816")
        try item.moveTo(Labs.LenientPanelAssignmentStatus.warming)
        #expect(item.status == Labs.LenientPanelAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newLenientPanelAssignment("code-476", name: "name-816")
        item.status = Labs.LenientPanelAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientPanelAssignmentStatus.idle) }
    }
}
