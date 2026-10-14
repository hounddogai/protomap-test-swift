@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingResultRule("code-92", name: "name-465")
        let view = Labs.toPendingResultRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingResultRuleViews([item, item]).count == 2)
    }
}
