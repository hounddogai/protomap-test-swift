@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyCensusDigest("code-45", label: "label-201")
        let view = BedManagement.toLegacyCensusDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyCensusDigestViews([item, item]).count == 2)
    }
}
