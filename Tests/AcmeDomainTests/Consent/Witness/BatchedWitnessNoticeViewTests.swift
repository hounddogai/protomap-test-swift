@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedWitnessNotice("code-31", label: "label-159")
        let view = Consent.toBatchedWitnessNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedWitnessNoticeViews([item, item]).count == 2)
    }
}
