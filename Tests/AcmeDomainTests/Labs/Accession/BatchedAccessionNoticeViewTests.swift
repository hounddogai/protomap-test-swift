@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedAccessionNotice("code-821", name: "name-522")
        let view = Labs.toBatchedAccessionNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedAccessionNoticeViews([item, item]).count == 2)
    }
}
