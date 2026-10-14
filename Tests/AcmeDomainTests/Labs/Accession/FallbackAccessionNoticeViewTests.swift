@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackAccessionNotice("code-286", name: "name-346")
        let view = Labs.toFallbackAccessionNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackAccessionNoticeViews([item, item]).count == 2)
    }
}
