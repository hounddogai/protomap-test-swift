@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictCensusDigest("code-460", title: "title-586")
        let view = BedManagement.toStrictCensusDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictCensusDigestViews([item, item]).count == 2)
    }
}
