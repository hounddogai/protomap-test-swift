@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionProfileTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAccessionProfile("code-516", label: "label-329")
        #expect(item.status == Labs.AccessionProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newAccessionProfile("code-516", label: "label-329")
        try item.moveTo(Labs.AccessionProfileStatus.published)
        #expect(item.status == Labs.AccessionProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAccessionProfile("code-516", label: "label-329")
        item.status = Labs.AccessionProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionProfileStatus.created) }
    }
}
