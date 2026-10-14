@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        let view = CareManagement.toBatchedOutreachPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedOutreachPolicyViews([item, item]).count == 2)
    }
}
