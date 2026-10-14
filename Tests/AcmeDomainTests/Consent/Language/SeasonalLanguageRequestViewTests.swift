@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        let view = Consent.toSeasonalLanguageRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalLanguageRequestViews([item, item]).count == 2)
    }
}
