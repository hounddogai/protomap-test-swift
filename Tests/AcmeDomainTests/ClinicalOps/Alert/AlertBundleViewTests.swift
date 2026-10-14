@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertBundle("code-806", label: "label-319")
        let view = ClinicalOps.toAlertBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertBundleViews([item, item]).count == 2)
    }
}
