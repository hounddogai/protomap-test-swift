@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageAdjustment("code-229", name: "name-558")
        let view = Consent.toLanguageAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageAdjustmentViews([item, item]).count == 2)
    }
}
