@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAuthorizationAssignment("code-832", name: "name-617")
        let view = RevenueCycle.toAuthorizationAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAuthorizationAssignmentViews([item, item]).count == 2)
    }
}
