@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientWitnessSchedule("code-886", title: "title-107")
        let view = Consent.toLenientWitnessScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientWitnessScheduleViews([item, item]).count == 2)
    }
}
