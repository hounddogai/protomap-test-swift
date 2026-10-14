@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistQuota("code-730", title: "title-495")
        let view = Imaging.toWorklistQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistQuotaViews([item, item]).count == 2)
    }
}
