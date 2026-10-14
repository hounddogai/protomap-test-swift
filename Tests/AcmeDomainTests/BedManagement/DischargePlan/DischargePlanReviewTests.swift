@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanReviewTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newDischargePlanReview("code-923", title: "title-646")
        #expect(item.status == BedManagement.DischargePlanReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newDischargePlanReview("code-923", title: "title-646")
        try item.moveTo(BedManagement.DischargePlanReviewStatus.validated)
        #expect(item.status == BedManagement.DischargePlanReviewStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newDischargePlanReview("code-923", title: "title-646")
        item.status = BedManagement.DischargePlanReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanReviewStatus.created) }
    }
}
