@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistRule("code-193", name: "name-612")
        let view = Imaging.toWorklistRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistRuleViews([item, item]).count == 2)
    }
}
