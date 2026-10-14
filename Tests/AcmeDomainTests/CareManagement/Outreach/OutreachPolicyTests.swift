@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPolicyTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        #expect(item.status == CareManagement.OutreachPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        try item.moveTo(CareManagement.OutreachPolicyStatus.validated)
        #expect(item.status == CareManagement.OutreachPolicyStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        item.status = CareManagement.OutreachPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachPolicyStatus.created) }
    }
}
