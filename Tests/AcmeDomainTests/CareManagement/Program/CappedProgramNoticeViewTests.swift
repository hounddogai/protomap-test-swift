@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedProgramNotice("code-646", name: "name-151")
        let view = CareManagement.toCappedProgramNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedProgramNoticeViews([item, item]).count == 2)
    }
}
