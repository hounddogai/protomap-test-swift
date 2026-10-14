@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureBaseline("code-122", label: "label-810")
        let view = Consent.toDisclosureBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureBaselineViews([item, item]).count == 2)
    }
}
