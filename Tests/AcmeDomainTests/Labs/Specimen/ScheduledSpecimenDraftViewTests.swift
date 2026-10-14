@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledSpecimenDraft("code-908", title: "title-2")
        let view = Labs.toScheduledSpecimenDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledSpecimenDraftViews([item, item]).count == 2)
    }
}
