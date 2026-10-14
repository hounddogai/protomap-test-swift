@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferEntry("code-131", label: "label-333")
        let view = BedManagement.toTransferEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferEntryViews([item, item]).count == 2)
    }
}
