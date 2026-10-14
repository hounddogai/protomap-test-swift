@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalWitnessNotice("code-894", name: "name-645")
        let view = Consent.toSeasonalWitnessNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalWitnessNoticeViews([item, item]).count == 2)
    }
}
