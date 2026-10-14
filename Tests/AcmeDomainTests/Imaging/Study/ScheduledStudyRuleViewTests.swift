@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        let view = Imaging.toScheduledStudyRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledStudyRuleViews([item, item]).count == 2)
    }
}
