@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDigestTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachDigest("code-898", name: "name-826")
        #expect(item.status == CareManagement.OutreachDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newOutreachDigest("code-898", name: "name-826")
        try item.moveTo(CareManagement.OutreachDigestStatus.failed)
        #expect(item.status == CareManagement.OutreachDigestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachDigest("code-898", name: "name-826")
        item.status = CareManagement.OutreachDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachDigestStatus.new) }
    }
}
