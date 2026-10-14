@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredCareGapAdjustment("code-652", title: "title-863")
        let view = CareManagement.toTieredCareGapAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredCareGapAdjustmentViews([item, item]).count == 2)
    }
}
