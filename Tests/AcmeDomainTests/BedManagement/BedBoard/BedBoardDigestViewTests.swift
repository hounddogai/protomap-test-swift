@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardDigest("code-466", label: "label-787")
        let view = BedManagement.toBedBoardDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardDigestViews([item, item]).count == 2)
    }
}
