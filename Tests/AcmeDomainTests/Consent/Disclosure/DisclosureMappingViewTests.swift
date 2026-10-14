@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureMapping("code-406", title: "title-881")
        let view = Consent.toDisclosureMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureMappingViews([item, item]).count == 2)
    }
}
