@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultOverrideTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultOverride("code-87", label: "label-57")
        #expect(item.status == Labs.ResultOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newResultOverride("code-87", label: "label-57")
        try item.moveTo(Labs.ResultOverrideStatus.granted)
        #expect(item.status == Labs.ResultOverrideStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultOverride("code-87", label: "label-57")
        item.status = Labs.ResultOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultOverrideStatus.requested) }
    }
}
