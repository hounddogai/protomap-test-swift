@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        let view = CareManagement.toRollingCareGapAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingCareGapAdjustmentViews([item, item]).count == 2)
    }
}
