@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationBundle("code-562", title: "title-765")
        let view = Consent.toRevocationBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationBundleViews([item, item]).count == 2)
    }
}
