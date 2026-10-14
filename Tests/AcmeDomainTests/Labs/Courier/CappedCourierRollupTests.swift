@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierRollupTests {
    @Test func startsInRequested() throws {
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        #expect(item.status == Labs.CappedCourierRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        try item.moveTo(Labs.CappedCourierRollupStatus.expired)
        #expect(item.status == Labs.CappedCourierRollupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        item.status = Labs.CappedCourierRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedCourierRollupStatus.requested) }
    }
}
