@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolQuota("code-556", label: "label-635")
        let view = Imaging.toCareProtocolQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolQuotaViews([item, item]).count == 2)
    }
}
