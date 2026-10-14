@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        let view = CareManagement.toGlobalCareGapNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalCareGapNoticeViews([item, item]).count == 2)
    }
}
