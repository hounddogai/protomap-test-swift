@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationRecord("code-81", label: "label-120")
        let view = BedManagement.toIsolationRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationRecordViews([item, item]).count == 2)
    }
}
