@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureBundle("code-389", title: "title-634")
        let view = Consent.toDisclosureBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureBundleViews([item, item]).count == 2)
    }
}
