@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLegacyAuthorizationEntry("code-710", label: "label-629")
        let view = RevenueCycle.toLegacyAuthorizationEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLegacyAuthorizationEntryViews([item, item]).count == 2)
    }
}
