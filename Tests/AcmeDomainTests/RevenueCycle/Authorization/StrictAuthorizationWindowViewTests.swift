@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictAuthorizationWindow("code-678", title: "title-300")
        let view = RevenueCycle.toStrictAuthorizationWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictAuthorizationWindowViews([item, item]).count == 2)
    }
}
