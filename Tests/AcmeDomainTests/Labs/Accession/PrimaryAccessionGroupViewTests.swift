@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        let view = Labs.toPrimaryAccessionGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryAccessionGroupViews([item, item]).count == 2)
    }
}
