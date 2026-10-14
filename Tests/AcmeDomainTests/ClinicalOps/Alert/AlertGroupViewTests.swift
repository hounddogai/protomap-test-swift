@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertGroup("code-378", label: "label-512")
        let view = ClinicalOps.toAlertGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertGroupViews([item, item]).count == 2)
    }
}
