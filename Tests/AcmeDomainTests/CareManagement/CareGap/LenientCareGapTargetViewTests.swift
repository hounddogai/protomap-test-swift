@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientCareGapTarget("code-789", label: "label-183")
        let view = CareManagement.toLenientCareGapTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientCareGapTargetViews([item, item]).count == 2)
    }
}
