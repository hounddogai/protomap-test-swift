@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        let view = CareManagement.toRegionalAssessmentNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalAssessmentNoticeViews([item, item]).count == 2)
    }
}
