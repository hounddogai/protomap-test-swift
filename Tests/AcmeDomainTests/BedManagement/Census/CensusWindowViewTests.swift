@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusWindow("code-358", name: "name-748")
        let view = BedManagement.toCensusWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusWindowViews([item, item]).count == 2)
    }
}
