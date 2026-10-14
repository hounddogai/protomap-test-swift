@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientOutreachSlot("code-853", title: "title-186")
        let view = CareManagement.toLenientOutreachSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientOutreachSlotViews([item, item]).count == 2)
    }
}
