@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusNotice("code-856", title: "title-509")
        let view = BedManagement.toCensusNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusNoticeViews([item, item]).count == 2)
    }
}
