@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenRequestTests {
    @Test func startsInRequested() throws {
        let item = Labs.newDefaultSpecimenRequest("code-392", name: "name-277")
        #expect(item.status == Labs.DefaultSpecimenRequestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newDefaultSpecimenRequest("code-392", name: "name-277")
        try item.moveTo(Labs.DefaultSpecimenRequestStatus.expired)
        #expect(item.status == Labs.DefaultSpecimenRequestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newDefaultSpecimenRequest("code-392", name: "name-277")
        item.status = Labs.DefaultSpecimenRequestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenRequestStatus.requested) }
    }
}
