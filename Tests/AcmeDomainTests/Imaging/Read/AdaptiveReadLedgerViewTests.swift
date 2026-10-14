@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveReadLedger("code-950", label: "label-124")
        let view = Imaging.toAdaptiveReadLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveReadLedgerViews([item, item]).count == 2)
    }
}
