@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalWitnessDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalWitnessDraft("code-637", label: "label-171")
        let view = Consent.toRegionalWitnessDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalWitnessDraftViews([item, item]).count == 2)
    }
}
