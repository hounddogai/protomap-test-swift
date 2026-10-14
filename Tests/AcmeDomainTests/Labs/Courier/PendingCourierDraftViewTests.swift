@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        let view = Labs.toPendingCourierDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingCourierDraftViews([item, item]).count == 2)
    }
}
