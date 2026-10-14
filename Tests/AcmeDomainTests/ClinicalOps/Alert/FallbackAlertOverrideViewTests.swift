@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        let view = ClinicalOps.toFallbackAlertOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackAlertOverrideViews([item, item]).count == 2)
    }
}
