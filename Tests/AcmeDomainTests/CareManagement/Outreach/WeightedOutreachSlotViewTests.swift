@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedOutreachSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedOutreachSlot("code-408", label: "label-407")
        let view = CareManagement.toWeightedOutreachSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedOutreachSlotViews([item, item]).count == 2)
    }
}
