@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeNotice("code-746", label: "label-661")
        let view = Labs.toReferenceRangeNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeNoticeViews([item, item]).count == 2)
    }
}
