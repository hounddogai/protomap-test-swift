@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        let view = CareManagement.toOutreachPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachPolicyViews([item, item]).count == 2)
    }
}
