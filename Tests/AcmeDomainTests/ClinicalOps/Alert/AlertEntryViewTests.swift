@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertEntry("code-152", title: "title-716")
        let view = ClinicalOps.toAlertEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertEntryViews([item, item]).count == 2)
    }
}
