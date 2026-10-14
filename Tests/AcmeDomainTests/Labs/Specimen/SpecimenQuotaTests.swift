@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenQuotaTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSpecimenQuota("code-557", name: "name-160")
        #expect(item.status == Labs.SpecimenQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newSpecimenQuota("code-557", name: "name-160")
        try item.moveTo(Labs.SpecimenQuotaStatus.withdrawn)
        #expect(item.status == Labs.SpecimenQuotaStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSpecimenQuota("code-557", name: "name-160")
        item.status = Labs.SpecimenQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenQuotaStatus.proposed) }
    }
}
