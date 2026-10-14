@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingSpecimenRule("code-544", name: "name-384")
        let view = Labs.toRollingSpecimenRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingSpecimenRuleViews([item, item]).count == 2)
    }
}
