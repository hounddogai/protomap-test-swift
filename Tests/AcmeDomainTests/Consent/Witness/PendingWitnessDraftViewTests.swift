@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingWitnessDraft("code-651", name: "name-667")
        let view = Consent.toPendingWitnessDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingWitnessDraftViews([item, item]).count == 2)
    }
}
