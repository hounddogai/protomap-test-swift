@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningRequest("code-422", name: "name-545")
        let view = BedManagement.toCleaningRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningRequestViews([item, item]).count == 2)
    }
}
