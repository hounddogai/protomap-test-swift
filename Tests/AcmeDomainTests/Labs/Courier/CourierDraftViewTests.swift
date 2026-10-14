@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierDraft("code-118", name: "name-961")
        let view = Labs.toCourierDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierDraftViews([item, item]).count == 2)
    }
}
