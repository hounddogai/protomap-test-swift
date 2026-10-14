@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedResultRule("code-243", name: "name-510")
        let view = Labs.toWeightedResultRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedResultRuleViews([item, item]).count == 2)
    }
}
