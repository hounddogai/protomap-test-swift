@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        let view = CareManagement.toLegacyProgramNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyProgramNoticeViews([item, item]).count == 2)
    }
}
