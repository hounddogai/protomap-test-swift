@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledReferenceRangeRule("code-496", name: "name-784")
        let view = Labs.toScheduledReferenceRangeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledReferenceRangeRuleViews([item, item]).count == 2)
    }
}
