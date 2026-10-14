@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachTarget("code-863", title: "title-988")
        let view = CareManagement.toOutreachTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachTargetViews([item, item]).count == 2)
    }
}
