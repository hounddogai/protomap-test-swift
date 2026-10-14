@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningRule("code-305", name: "name-894")
        let view = BedManagement.toCleaningRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningRuleViews([item, item]).count == 2)
    }
}
