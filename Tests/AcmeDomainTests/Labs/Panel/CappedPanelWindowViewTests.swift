@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedPanelWindow("code-439", title: "title-244")
        let view = Labs.toCappedPanelWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedPanelWindowViews([item, item]).count == 2)
    }
}
