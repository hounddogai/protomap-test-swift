@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAuthorizationEntry("code-796", name: "name-248")
        let view = RevenueCycle.toAuthorizationEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAuthorizationEntryViews([item, item]).count == 2)
    }
}
