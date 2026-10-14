@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        let view = Imaging.toPendingModalityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingModalityQuotaViews([item, item]).count == 2)
    }
}
