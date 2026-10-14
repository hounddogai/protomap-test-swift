@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusRequest("code-132", label: "label-411")
        let view = BedManagement.toCensusRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusRequestViews([item, item]).count == 2)
    }
}
