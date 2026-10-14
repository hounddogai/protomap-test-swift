@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionNotice("code-65", label: "label-572")
        let view = Labs.toAccessionNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionNoticeViews([item, item]).count == 2)
    }
}
