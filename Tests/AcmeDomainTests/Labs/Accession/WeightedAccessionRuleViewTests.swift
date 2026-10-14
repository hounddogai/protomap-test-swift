@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedAccessionRule("code-788", title: "title-174")
        let view = Labs.toWeightedAccessionRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedAccessionRuleViews([item, item]).count == 2)
    }
}
