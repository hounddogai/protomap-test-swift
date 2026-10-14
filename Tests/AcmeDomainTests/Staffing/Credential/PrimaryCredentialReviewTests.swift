@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialReviewTests {
    @Test func startsInNew() throws {
        let item = Staffing.newPrimaryCredentialReview("code-701", label: "label-832")
        #expect(item.status == Staffing.PrimaryCredentialReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newPrimaryCredentialReview("code-701", label: "label-832")
        try item.moveTo(Staffing.PrimaryCredentialReviewStatus.running)
        #expect(item.status == Staffing.PrimaryCredentialReviewStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newPrimaryCredentialReview("code-701", label: "label-832")
        item.status = Staffing.PrimaryCredentialReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryCredentialReviewStatus.new) }
    }
}
