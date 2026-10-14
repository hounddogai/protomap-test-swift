@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        let view = Labs.toCourierAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierAuditViews([item, item]).count == 2)
    }
}
