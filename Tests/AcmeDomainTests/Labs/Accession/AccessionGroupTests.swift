@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionGroupTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionGroup("code-617", label: "label-386")
        #expect(item.status == Labs.AccessionGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newAccessionGroup("code-617", label: "label-386")
        try item.moveTo(Labs.AccessionGroupStatus.expired)
        #expect(item.status == Labs.AccessionGroupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionGroup("code-617", label: "label-386")
        item.status = Labs.AccessionGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionGroupStatus.requested) }
    }
}
