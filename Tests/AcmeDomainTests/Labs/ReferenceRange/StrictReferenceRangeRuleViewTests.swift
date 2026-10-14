@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newStrictReferenceRangeRule("code-413", name: "name-446")
        let view = Labs.toStrictReferenceRangeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toStrictReferenceRangeRuleViews([item, item]).count == 2)
    }
}
