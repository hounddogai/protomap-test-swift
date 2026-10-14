@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDigestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierDigest("code-686", label: "label-238")
        #expect(item.status == Labs.CourierDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newCourierDigest("code-686", label: "label-238")
        try item.moveTo(Labs.CourierDigestStatus.approved)
        #expect(item.status == Labs.CourierDigestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierDigest("code-686", label: "label-238")
        item.status = Labs.CourierDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierDigestStatus.proposed) }
    }
}
