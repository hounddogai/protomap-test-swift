@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedCleaningRecord("code-535", label: "label-737")
        let view = BedManagement.toBatchedCleaningRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedCleaningRecordViews([item, item]).count == 2)
    }
}
