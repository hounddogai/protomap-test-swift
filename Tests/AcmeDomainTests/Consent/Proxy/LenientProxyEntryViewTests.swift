@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientProxyEntry("code-938", label: "label-789")
        let view = Consent.toLenientProxyEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientProxyEntryViews([item, item]).count == 2)
    }
}
