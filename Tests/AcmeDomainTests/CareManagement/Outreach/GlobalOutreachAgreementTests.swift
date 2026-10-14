@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachAgreementTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newGlobalOutreachAgreement("code-992", title: "title-52")
        #expect(item.status == CareManagement.GlobalOutreachAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newGlobalOutreachAgreement("code-992", title: "title-52")
        try item.moveTo(CareManagement.GlobalOutreachAgreementStatus.ready)
        #expect(item.status == CareManagement.GlobalOutreachAgreementStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newGlobalOutreachAgreement("code-992", title: "title-52")
        item.status = CareManagement.GlobalOutreachAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalOutreachAgreementStatus.idle) }
    }
}
