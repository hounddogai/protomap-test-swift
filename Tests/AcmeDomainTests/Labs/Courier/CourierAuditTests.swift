@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAuditTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        #expect(item.status == Labs.CourierAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        try item.moveTo(Labs.CourierAuditStatus.approved)
        #expect(item.status == Labs.CourierAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        item.status = Labs.CourierAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierAuditStatus.proposed) }
    }
}
