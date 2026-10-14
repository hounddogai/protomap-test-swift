@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedClaimAssignment("code-110", title: "title-76")
        let view = RevenueCycle.toBatchedClaimAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedClaimAssignmentViews([item, item]).count == 2)
    }
}
