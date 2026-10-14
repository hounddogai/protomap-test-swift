@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveOutreachTier("code-111", title: "title-196")
        let view = CareManagement.toAdaptiveOutreachTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveOutreachTierViews([item, item]).count == 2)
    }
}
