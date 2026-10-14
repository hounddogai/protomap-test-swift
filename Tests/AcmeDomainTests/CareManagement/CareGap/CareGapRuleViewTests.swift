@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        let view = CareManagement.toCareGapRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapRuleViews([item, item]).count == 2)
    }
}
