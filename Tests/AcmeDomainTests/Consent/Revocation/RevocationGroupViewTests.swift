@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationGroup("code-113", label: "label-846")
        let view = Consent.toRevocationGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationGroupViews([item, item]).count == 2)
    }
}
