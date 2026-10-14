@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityQuota("code-277", title: "title-160")
        let view = Imaging.toModalityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityQuotaViews([item, item]).count == 2)
    }
}
