@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessRecord("code-433", title: "title-900")
        let view = Consent.toWitnessRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessRecordViews([item, item]).count == 2)
    }
}
