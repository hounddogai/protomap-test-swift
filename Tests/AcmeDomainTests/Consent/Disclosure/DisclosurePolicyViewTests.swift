@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosurePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosurePolicy("code-417", name: "name-496")
        let view = Consent.toDisclosurePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosurePolicyViews([item, item]).count == 2)
    }
}
