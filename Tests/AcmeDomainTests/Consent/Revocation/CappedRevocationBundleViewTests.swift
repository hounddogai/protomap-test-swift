@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        let view = Consent.toCappedRevocationBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedRevocationBundleViews([item, item]).count == 2)
    }
}
