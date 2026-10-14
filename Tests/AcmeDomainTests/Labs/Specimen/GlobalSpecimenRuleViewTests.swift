@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalSpecimenRule("code-950", title: "title-597")
        let view = Labs.toGlobalSpecimenRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalSpecimenRuleViews([item, item]).count == 2)
    }
}
