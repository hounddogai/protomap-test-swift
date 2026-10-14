@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramNotice("code-819", title: "title-565")
        let view = CareManagement.toProgramNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramNoticeViews([item, item]).count == 2)
    }
}
