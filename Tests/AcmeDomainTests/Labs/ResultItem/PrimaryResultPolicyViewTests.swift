@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryResultPolicy("code-997", title: "title-232")
        let view = Labs.toPrimaryResultPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryResultPolicyViews([item, item]).count == 2)
    }
}
