@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryCleaningBatch("code-914", name: "name-354")
        let view = BedManagement.toPrimaryCleaningBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryCleaningBatchViews([item, item]).count == 2)
    }
}
