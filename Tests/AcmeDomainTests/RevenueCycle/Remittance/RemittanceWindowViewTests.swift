@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittanceWindow("code-322", title: "title-155")
        let view = RevenueCycle.toRemittanceWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittanceWindowViews([item, item]).count == 2)
    }
}
