@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureNotice("code-788", title: "title-294")
        let view = Consent.toDisclosureNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureNoticeViews([item, item]).count == 2)
    }
}
