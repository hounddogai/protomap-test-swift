@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolPolicy("code-650", name: "name-903")
        let view = Imaging.toCareProtocolPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolPolicyViews([item, item]).count == 2)
    }
}
