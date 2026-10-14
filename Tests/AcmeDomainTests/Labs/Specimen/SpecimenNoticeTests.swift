@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenNoticeTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSpecimenNotice("code-576", label: "label-322")
        #expect(item.status == Labs.SpecimenNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newSpecimenNotice("code-576", label: "label-322")
        try item.moveTo(Labs.SpecimenNoticeStatus.approved)
        #expect(item.status == Labs.SpecimenNoticeStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSpecimenNotice("code-576", label: "label-322")
        item.status = Labs.SpecimenNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenNoticeStatus.proposed) }
    }
}
