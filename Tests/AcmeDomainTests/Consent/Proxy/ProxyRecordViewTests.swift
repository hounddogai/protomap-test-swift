@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyRecord("code-440", name: "name-274")
        let view = Consent.toProxyRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyRecordViews([item, item]).count == 2)
    }
}
