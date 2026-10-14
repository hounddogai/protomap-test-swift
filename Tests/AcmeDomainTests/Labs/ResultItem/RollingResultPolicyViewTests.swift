@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingResultPolicy("code-605", name: "name-679")
        let view = Labs.toRollingResultPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingResultPolicyViews([item, item]).count == 2)
    }
}
