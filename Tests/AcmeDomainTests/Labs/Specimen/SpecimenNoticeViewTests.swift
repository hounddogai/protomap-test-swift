@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenNotice("code-576", label: "label-322")
        let view = Labs.toSpecimenNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenNoticeViews([item, item]).count == 2)
    }
}
