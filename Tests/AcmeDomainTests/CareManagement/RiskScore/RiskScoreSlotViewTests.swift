@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRiskScoreSlot("code-247", title: "title-234")
        let view = CareManagement.toRiskScoreSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRiskScoreSlotViews([item, item]).count == 2)
    }
}
