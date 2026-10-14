@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingCleaningRecord("code-694", title: "title-430")
        let view = BedManagement.toRollingCleaningRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingCleaningRecordViews([item, item]).count == 2)
    }
}
