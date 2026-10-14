@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryDisclosureRecord("code-562", name: "name-113")
        let view = Consent.toPrimaryDisclosureRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryDisclosureRecordViews([item, item]).count == 2)
    }
}
