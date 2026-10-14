@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureGroup("code-933", label: "label-460")
        let view = Consent.toDisclosureGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureGroupViews([item, item]).count == 2)
    }
}
