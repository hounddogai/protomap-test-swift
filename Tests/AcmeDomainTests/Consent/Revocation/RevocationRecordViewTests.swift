@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationRecord("code-847", label: "label-832")
        let view = Consent.toRevocationRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationRecordViews([item, item]).count == 2)
    }
}
