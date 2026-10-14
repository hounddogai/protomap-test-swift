@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalCareProtocolPolicy("code-322", name: "name-809")
        let view = Imaging.toSeasonalCareProtocolPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalCareProtocolPolicyViews([item, item]).count == 2)
    }
}
