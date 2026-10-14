@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        let view = Consent.toLanguageTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageTierViews([item, item]).count == 2)
    }
}
