@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationRule("code-124", title: "title-78")
        let view = BedManagement.toIsolationRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationRuleViews([item, item]).count == 2)
    }
}
