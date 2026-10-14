@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultResultAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultResultAudit("code-726", title: "title-105")
        let view = Labs.toDefaultResultAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultResultAuditViews([item, item]).count == 2)
    }
}
