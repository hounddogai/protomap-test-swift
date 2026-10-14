@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageSummary("code-649", title: "title-616")
        let view = Consent.toLanguageSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageSummaryViews([item, item]).count == 2)
    }
}
