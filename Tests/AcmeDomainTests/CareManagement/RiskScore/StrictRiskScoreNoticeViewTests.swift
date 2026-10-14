@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictRiskScoreNotice("code-839", name: "name-423")
        let view = CareManagement.toStrictRiskScoreNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictRiskScoreNoticeViews([item, item]).count == 2)
    }
}
