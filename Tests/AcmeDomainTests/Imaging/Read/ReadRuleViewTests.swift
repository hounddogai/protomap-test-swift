@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadRule("code-388", name: "name-817")
        let view = Imaging.toReadRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadRuleViews([item, item]).count == 2)
    }
}
