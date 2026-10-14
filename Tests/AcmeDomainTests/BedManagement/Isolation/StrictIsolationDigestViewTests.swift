@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictIsolationDigest("code-570", title: "title-168")
        let view = BedManagement.toStrictIsolationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictIsolationDigestViews([item, item]).count == 2)
    }
}
