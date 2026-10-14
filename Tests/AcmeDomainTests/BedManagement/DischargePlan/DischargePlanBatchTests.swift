@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanBatchTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newDischargePlanBatch("code-656", label: "label-890")
        #expect(item.status == BedManagement.DischargePlanBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newDischargePlanBatch("code-656", label: "label-890")
        try item.moveTo(BedManagement.DischargePlanBatchStatus.inReview)
        #expect(item.status == BedManagement.DischargePlanBatchStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newDischargePlanBatch("code-656", label: "label-890")
        item.status = BedManagement.DischargePlanBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanBatchStatus.`open`) }
    }
}
