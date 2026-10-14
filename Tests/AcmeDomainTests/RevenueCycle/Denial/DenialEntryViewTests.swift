@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialEntry("code-973", title: "title-738")
        let view = RevenueCycle.toDenialEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialEntryViews([item, item]).count == 2)
    }
}
