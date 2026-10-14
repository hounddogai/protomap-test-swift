@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualWitnessBatch("code-453", name: "name-715")
        let view = Consent.toManualWitnessBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualWitnessBatchViews([item, item]).count == 2)
    }
}
