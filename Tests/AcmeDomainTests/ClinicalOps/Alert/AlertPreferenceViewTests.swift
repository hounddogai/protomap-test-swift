@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertPreference("code-106", label: "label-226")
        let view = ClinicalOps.toAlertPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertPreferenceViews([item, item]).count == 2)
    }
}
