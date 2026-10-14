@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLegacyAuthorizationSegment("code-727", title: "title-232")
        let view = RevenueCycle.toLegacyAuthorizationSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLegacyAuthorizationSegmentViews([item, item]).count == 2)
    }
}
