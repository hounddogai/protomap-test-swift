@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenEntryTests {
    @Test func startsInRequested() throws {
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        #expect(item.status == Labs.RollingSpecimenEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        try item.moveTo(Labs.RollingSpecimenEntryStatus.revoked)
        #expect(item.status == Labs.RollingSpecimenEntryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        item.status = Labs.RollingSpecimenEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingSpecimenEntryStatus.requested) }
    }
}
