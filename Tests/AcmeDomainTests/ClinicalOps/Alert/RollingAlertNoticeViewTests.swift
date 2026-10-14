@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingAlertNotice("code-833", name: "name-119")
        let view = ClinicalOps.toRollingAlertNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingAlertNoticeViews([item, item]).count == 2)
    }
}
