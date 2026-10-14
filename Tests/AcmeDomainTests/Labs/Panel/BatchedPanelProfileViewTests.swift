@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedPanelProfile("code-33", title: "title-608")
        let view = Labs.toBatchedPanelProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedPanelProfileViews([item, item]).count == 2)
    }
}
