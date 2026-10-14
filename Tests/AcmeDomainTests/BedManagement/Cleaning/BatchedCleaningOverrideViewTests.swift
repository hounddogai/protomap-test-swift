@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedCleaningOverride("code-130", title: "title-668")
        let view = BedManagement.toBatchedCleaningOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedCleaningOverrideViews([item, item]).count == 2)
    }
}
