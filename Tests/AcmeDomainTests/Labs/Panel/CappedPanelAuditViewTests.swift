@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedPanelAudit("code-250", name: "name-817")
        let view = Labs.toCappedPanelAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedPanelAuditViews([item, item]).count == 2)
    }
}
