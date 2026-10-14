@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityAgreementTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRollingPriorityAgreement("code-755", title: "title-462")
        #expect(item.status == Imaging.RollingPriorityAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newRollingPriorityAgreement("code-755", title: "title-462")
        try item.moveTo(Imaging.RollingPriorityAgreementStatus.running)
        #expect(item.status == Imaging.RollingPriorityAgreementStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRollingPriorityAgreement("code-755", title: "title-462")
        item.status = Imaging.RollingPriorityAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingPriorityAgreementStatus.new) }
    }
}
