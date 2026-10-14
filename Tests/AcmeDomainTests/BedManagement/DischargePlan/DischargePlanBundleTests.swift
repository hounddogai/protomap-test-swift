@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanBundleTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanBundle("code-848", label: "label-645")
        #expect(item.status == BedManagement.DischargePlanBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newDischargePlanBundle("code-848", label: "label-645")
        try item.moveTo(BedManagement.DischargePlanBundleStatus.active)
        #expect(item.status == BedManagement.DischargePlanBundleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanBundle("code-848", label: "label-645")
        item.status = BedManagement.DischargePlanBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanBundleStatus.draft) }
    }
}
