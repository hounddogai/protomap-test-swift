@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningProfile("code-143", name: "name-971")
        let view = BedManagement.toCleaningProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningProfileViews([item, item]).count == 2)
    }
}
