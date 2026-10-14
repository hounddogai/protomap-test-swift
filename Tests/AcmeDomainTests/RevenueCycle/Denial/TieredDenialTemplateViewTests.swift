@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredDenialTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredDenialTemplate("code-236", title: "title-679")
        let view = RevenueCycle.toTieredDenialTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredDenialTemplateViews([item, item]).count == 2)
    }
}
