@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityRule("code-91", title: "title-906")
        let view = Imaging.toModalityRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityRuleViews([item, item]).count == 2)
    }
}
