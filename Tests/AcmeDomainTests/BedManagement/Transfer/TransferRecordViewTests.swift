@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferRecord("code-703", label: "label-667")
        let view = BedManagement.toTransferRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferRecordViews([item, item]).count == 2)
    }
}
