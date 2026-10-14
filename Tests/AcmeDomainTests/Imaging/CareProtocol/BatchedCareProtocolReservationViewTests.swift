@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedCareProtocolReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newBatchedCareProtocolReservation("code-637", name: "name-223")
        let view = Imaging.toBatchedCareProtocolReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toBatchedCareProtocolReservationViews([item, item]).count == 2)
    }
}
