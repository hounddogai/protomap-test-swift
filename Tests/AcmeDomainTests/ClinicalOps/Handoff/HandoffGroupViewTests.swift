@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newHandoffGroup("code-719", title: "title-893")
        let view = ClinicalOps.toHandoffGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toHandoffGroupViews([item, item]).count == 2)
    }
}
