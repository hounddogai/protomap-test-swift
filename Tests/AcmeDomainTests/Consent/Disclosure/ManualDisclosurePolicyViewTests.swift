@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualDisclosurePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualDisclosurePolicy("code-129", title: "title-739")
        let view = Consent.toManualDisclosurePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualDisclosurePolicyViews([item, item]).count == 2)
    }
}
