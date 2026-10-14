@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionAudit("code-814", label: "label-881")
        let view = Labs.toAccessionAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionAuditViews([item, item]).count == 2)
    }
}
