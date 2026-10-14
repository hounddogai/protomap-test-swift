@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenPolicyTests {
    @Test func startsInRequested() throws {
        let item = Labs.newLenientSpecimenPolicy("code-486", title: "title-474")
        #expect(item.status == Labs.LenientSpecimenPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newLenientSpecimenPolicy("code-486", title: "title-474")
        try item.moveTo(Labs.LenientSpecimenPolicyStatus.granted)
        #expect(item.status == Labs.LenientSpecimenPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newLenientSpecimenPolicy("code-486", title: "title-474")
        item.status = Labs.LenientSpecimenPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientSpecimenPolicyStatus.requested) }
    }
}
