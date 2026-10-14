@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessSchedule("code-543", title: "title-193")
        let view = Consent.toWitnessScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessScheduleViews([item, item]).count == 2)
    }
}
