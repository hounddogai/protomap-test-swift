@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeRule("code-49", label: "label-735")
        let view = Labs.toReferenceRangeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeRuleViews([item, item]).count == 2)
    }
}
