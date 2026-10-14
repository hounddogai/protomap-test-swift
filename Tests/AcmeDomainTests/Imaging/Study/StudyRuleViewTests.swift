@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyRule("code-802", name: "name-36")
        let view = Imaging.toStudyRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyRuleViews([item, item]).count == 2)
    }
}
