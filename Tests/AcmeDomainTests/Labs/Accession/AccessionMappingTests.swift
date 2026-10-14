@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMappingTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionMapping("code-774", title: "title-972")
        #expect(item.status == Labs.AccessionMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newAccessionMapping("code-774", title: "title-972")
        try item.moveTo(Labs.AccessionMappingStatus.revoked)
        #expect(item.status == Labs.AccessionMappingStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionMapping("code-774", title: "title-972")
        item.status = Labs.AccessionMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionMappingStatus.requested) }
    }
}
