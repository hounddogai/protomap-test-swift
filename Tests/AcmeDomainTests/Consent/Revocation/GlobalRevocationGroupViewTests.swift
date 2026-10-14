@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalRevocationGroup("code-257", title: "title-548")
        let view = Consent.toGlobalRevocationGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalRevocationGroupViews([item, item]).count == 2)
    }
}
