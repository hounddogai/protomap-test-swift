@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenDraft("code-253", name: "name-32")
        let view = Labs.toSpecimenDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenDraftViews([item, item]).count == 2)
    }
}
