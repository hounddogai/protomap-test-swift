@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingCareProtocolRule("code-301", title: "title-496")
        let view = Imaging.toRollingCareProtocolRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingCareProtocolRuleViews([item, item]).count == 2)
    }
}
