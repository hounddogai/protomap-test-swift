@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualOutreachSlot("code-92", name: "name-126")
        let view = CareManagement.toManualOutreachSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualOutreachSlotViews([item, item]).count == 2)
    }
}
