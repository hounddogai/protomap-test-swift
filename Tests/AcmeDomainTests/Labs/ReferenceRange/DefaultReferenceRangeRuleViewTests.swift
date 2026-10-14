@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultReferenceRangeRule("code-147", title: "title-495")
        let view = Labs.toDefaultReferenceRangeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultReferenceRangeRuleViews([item, item]).count == 2)
    }
}
