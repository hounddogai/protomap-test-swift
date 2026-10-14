@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCensusRecord("code-199", label: "label-570")
        let view = BedManagement.toLenientCensusRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCensusRecordViews([item, item]).count == 2)
    }
}
