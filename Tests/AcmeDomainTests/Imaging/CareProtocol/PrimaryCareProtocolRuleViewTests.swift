@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryCareProtocolRule("code-942", title: "title-734")
        let view = Imaging.toPrimaryCareProtocolRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryCareProtocolRuleViews([item, item]).count == 2)
    }
}
