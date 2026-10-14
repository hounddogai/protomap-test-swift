@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedDischargePlanDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedDischargePlanDraft("code-521", name: "name-944")
        let view = BedManagement.toBatchedDischargePlanDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedDischargePlanDraftViews([item, item]).count == 2)
    }
}
