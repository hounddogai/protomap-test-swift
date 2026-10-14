@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveCareGapOverride("code-868", label: "label-915")
        let view = CareManagement.toAdaptiveCareGapOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveCareGapOverrideViews([item, item]).count == 2)
    }
}
