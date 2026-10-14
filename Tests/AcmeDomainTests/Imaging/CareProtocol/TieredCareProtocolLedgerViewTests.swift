@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredCareProtocolLedger("code-185", name: "name-767")
        let view = Imaging.toTieredCareProtocolLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredCareProtocolLedgerViews([item, item]).count == 2)
    }
}
