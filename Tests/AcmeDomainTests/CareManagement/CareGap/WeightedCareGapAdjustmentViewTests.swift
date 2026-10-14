@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedCareGapAdjustment("code-971", title: "title-801")
        let view = CareManagement.toWeightedCareGapAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedCareGapAdjustmentViews([item, item]).count == 2)
    }
}
