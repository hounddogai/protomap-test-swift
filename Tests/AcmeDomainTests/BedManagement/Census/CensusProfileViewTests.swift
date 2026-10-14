@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusProfile("code-36", title: "title-382")
        let view = BedManagement.toCensusProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusProfileViews([item, item]).count == 2)
    }
}
