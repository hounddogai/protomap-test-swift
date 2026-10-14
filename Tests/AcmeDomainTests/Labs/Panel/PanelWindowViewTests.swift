@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelWindow("code-648", name: "name-974")
        let view = Labs.toPanelWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelWindowViews([item, item]).count == 2)
    }
}
