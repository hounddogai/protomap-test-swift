@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormSchedule("code-449", title: "title-544")
        let view = Consent.toConsentFormScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormScheduleViews([item, item]).count == 2)
    }
}
