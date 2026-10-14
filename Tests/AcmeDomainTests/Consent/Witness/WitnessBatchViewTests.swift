@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessBatch("code-541", label: "label-902")
        let view = Consent.toWitnessBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessBatchViews([item, item]).count == 2)
    }
}
