@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalProxyGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalProxyGroup("code-786", title: "title-713")
        let view = Consent.toSeasonalProxyGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalProxyGroupViews([item, item]).count == 2)
    }
}
