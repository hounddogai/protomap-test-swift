@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        let view = CareManagement.toGlobalGoalEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalGoalEntryViews([item, item]).count == 2)
    }
}
