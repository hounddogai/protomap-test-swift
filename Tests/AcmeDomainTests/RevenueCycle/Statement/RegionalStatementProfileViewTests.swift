@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalStatementProfile("code-74", title: "title-602")
        let view = RevenueCycle.toRegionalStatementProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalStatementProfileViews([item, item]).count == 2)
    }
}
