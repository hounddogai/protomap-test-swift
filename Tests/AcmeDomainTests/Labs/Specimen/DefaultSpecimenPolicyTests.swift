@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPolicyTests {
    @Test func startsInCreated() throws {
        let item = Labs.newDefaultSpecimenPolicy("code-895", name: "name-164")
        #expect(item.status == Labs.DefaultSpecimenPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newDefaultSpecimenPolicy("code-895", name: "name-164")
        try item.moveTo(Labs.DefaultSpecimenPolicyStatus.validated)
        #expect(item.status == Labs.DefaultSpecimenPolicyStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newDefaultSpecimenPolicy("code-895", name: "name-164")
        item.status = Labs.DefaultSpecimenPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenPolicyStatus.created) }
    }
}
