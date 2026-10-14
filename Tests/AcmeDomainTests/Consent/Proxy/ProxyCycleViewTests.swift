@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        let view = Consent.toProxyCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyCycleViews([item, item]).count == 2)
    }
}
