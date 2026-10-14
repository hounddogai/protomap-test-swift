@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskGroup("code-781", title: "title-37")
        let view = ClinicalOps.toTaskGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskGroupViews([item, item]).count == 2)
    }
}
