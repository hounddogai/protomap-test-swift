@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessPlan("code-50", label: "label-508")
        let view = Consent.toWitnessPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessPlanViews([item, item]).count == 2)
    }
}
