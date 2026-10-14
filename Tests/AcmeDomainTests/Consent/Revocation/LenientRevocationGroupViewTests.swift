@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        let view = Consent.toLenientRevocationGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientRevocationGroupViews([item, item]).count == 2)
    }
}
