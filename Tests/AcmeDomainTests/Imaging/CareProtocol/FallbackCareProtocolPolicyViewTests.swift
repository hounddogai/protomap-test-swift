@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackCareProtocolPolicy("code-962", title: "title-368")
        let view = Imaging.toFallbackCareProtocolPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackCareProtocolPolicyViews([item, item]).count == 2)
    }
}
