@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalAlertNotice("code-369", label: "label-865")
        let view = ClinicalOps.toRegionalAlertNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalAlertNoticeViews([item, item]).count == 2)
    }
}
