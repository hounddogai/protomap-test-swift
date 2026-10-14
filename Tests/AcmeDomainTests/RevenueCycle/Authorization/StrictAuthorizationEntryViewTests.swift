@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictAuthorizationEntry("code-513", label: "label-897")
        let view = RevenueCycle.toStrictAuthorizationEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictAuthorizationEntryViews([item, item]).count == 2)
    }
}
