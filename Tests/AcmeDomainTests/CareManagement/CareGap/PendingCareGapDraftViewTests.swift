@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingCareGapDraft("code-588", name: "name-369")
        let view = CareManagement.toPendingCareGapDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingCareGapDraftViews([item, item]).count == 2)
    }
}
