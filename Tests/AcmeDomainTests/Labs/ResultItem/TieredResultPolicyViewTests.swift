@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        let view = Labs.toTieredResultPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toTieredResultPolicyViews([item, item]).count == 2)
    }
}
