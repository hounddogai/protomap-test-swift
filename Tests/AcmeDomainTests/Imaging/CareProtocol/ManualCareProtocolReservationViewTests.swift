@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualCareProtocolReservation("code-603", label: "label-531")
        let view = Imaging.toManualCareProtocolReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualCareProtocolReservationViews([item, item]).count == 2)
    }
}
