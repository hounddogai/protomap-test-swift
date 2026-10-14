@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictCourierTargetTests {
    @Test func startsInNew() throws {
        let item = Labs.newStrictCourierTarget("code-946", name: "name-762")
        #expect(item.status == Labs.StrictCourierTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newStrictCourierTarget("code-946", name: "name-762")
        try item.moveTo(Labs.StrictCourierTargetStatus.running)
        #expect(item.status == Labs.StrictCourierTargetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newStrictCourierTarget("code-946", name: "name-762")
        item.status = Labs.StrictCourierTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictCourierTargetStatus.new) }
    }
}
