@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapAdjustment("code-532", label: "label-948")
        let view = CareManagement.toCareGapAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapAdjustmentViews([item, item]).count == 2)
    }
}
