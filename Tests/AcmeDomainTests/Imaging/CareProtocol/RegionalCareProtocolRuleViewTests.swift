@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalCareProtocolRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalCareProtocolRule("code-754", label: "label-306")
        let view = Imaging.toRegionalCareProtocolRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalCareProtocolRuleViews([item, item]).count == 2)
    }
}
