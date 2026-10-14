@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialGroup("code-862", title: "title-252")
        let view = RevenueCycle.toDenialGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialGroupViews([item, item]).count == 2)
    }
}
