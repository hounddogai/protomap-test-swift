@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationDigest("code-495", title: "title-515")
        let view = BedManagement.toIsolationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationDigestViews([item, item]).count == 2)
    }
}
