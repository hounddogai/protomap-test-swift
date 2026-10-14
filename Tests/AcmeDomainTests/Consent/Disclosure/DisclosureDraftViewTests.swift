@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureDraft("code-660", label: "label-389")
        let view = Consent.toDisclosureDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureDraftViews([item, item]).count == 2)
    }
}
