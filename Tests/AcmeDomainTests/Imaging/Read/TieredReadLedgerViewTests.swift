@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        let view = Imaging.toTieredReadLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredReadLedgerViews([item, item]).count == 2)
    }
}
