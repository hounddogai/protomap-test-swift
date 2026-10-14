@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        let view = CareManagement.toBatchedOutreachCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedOutreachCycleViews([item, item]).count == 2)
    }
}
