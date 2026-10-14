@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedCleaningCycle("code-335", title: "title-123")
        let view = BedManagement.toBatchedCleaningCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedCleaningCycleViews([item, item]).count == 2)
    }
}
