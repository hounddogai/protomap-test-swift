@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertNotice("code-143", name: "name-204")
        let view = ClinicalOps.toAlertNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertNoticeViews([item, item]).count == 2)
    }
}
