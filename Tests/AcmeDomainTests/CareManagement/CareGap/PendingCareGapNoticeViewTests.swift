@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        let view = CareManagement.toPendingCareGapNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingCareGapNoticeViews([item, item]).count == 2)
    }
}
