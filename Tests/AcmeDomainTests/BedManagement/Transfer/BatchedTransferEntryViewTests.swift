@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedTransferEntry("code-118", name: "name-977")
        let view = BedManagement.toBatchedTransferEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedTransferEntryViews([item, item]).count == 2)
    }
}
