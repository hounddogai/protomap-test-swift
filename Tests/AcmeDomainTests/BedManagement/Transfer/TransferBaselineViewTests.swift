@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferBaseline("code-971", label: "label-591")
        let view = BedManagement.toTransferBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferBaselineViews([item, item]).count == 2)
    }
}
