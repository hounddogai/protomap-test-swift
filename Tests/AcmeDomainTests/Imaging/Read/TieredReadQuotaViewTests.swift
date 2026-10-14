@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredReadQuota("code-874", title: "title-150")
        let view = Imaging.toTieredReadQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredReadQuotaViews([item, item]).count == 2)
    }
}
