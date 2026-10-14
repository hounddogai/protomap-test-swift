@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingProgramNotice("code-789", name: "name-488")
        let view = CareManagement.toPendingProgramNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingProgramNoticeViews([item, item]).count == 2)
    }
}
