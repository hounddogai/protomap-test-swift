@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolLedger("code-697", label: "label-758")
        let view = Imaging.toCareProtocolLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolLedgerViews([item, item]).count == 2)
    }
}
