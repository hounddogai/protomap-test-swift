@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveCareGapBundle("code-413", label: "label-329")
        let view = CareManagement.toAdaptiveCareGapBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveCareGapBundleViews([item, item]).count == 2)
    }
}
