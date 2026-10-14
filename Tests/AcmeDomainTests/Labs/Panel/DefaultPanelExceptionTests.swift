@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultPanelExceptionTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultPanelException("code-535", label: "label-781")
        #expect(item.status == Labs.DefaultPanelExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newDefaultPanelException("code-535", label: "label-781")
        try item.moveTo(Labs.DefaultPanelExceptionStatus.approved)
        #expect(item.status == Labs.DefaultPanelExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultPanelException("code-535", label: "label-781")
        item.status = Labs.DefaultPanelExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultPanelExceptionStatus.proposed) }
    }
}
