@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingModalityPolicy("code-626", title: "title-304")
        let view = Imaging.toPendingModalityPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingModalityPolicyViews([item, item]).count == 2)
    }
}
