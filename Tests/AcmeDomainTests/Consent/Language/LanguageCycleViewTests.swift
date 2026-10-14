@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageCycle("code-873", label: "label-1")
        let view = Consent.toLanguageCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageCycleViews([item, item]).count == 2)
    }
}
