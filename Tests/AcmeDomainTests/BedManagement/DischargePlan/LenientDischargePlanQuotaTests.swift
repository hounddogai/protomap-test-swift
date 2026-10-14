@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanQuotaTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newLenientDischargePlanQuota("code-362", label: "label-262")
        #expect(item.status == BedManagement.LenientDischargePlanQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newLenientDischargePlanQuota("code-362", label: "label-262")
        try item.moveTo(BedManagement.LenientDischargePlanQuotaStatus.published)
        #expect(item.status == BedManagement.LenientDischargePlanQuotaStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newLenientDischargePlanQuota("code-362", label: "label-262")
        item.status = BedManagement.LenientDischargePlanQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientDischargePlanQuotaStatus.created) }
    }
}
