@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadReservation("code-342", label: "label-456")
        let view = Imaging.toReadReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadReservationViews([item, item]).count == 2)
    }
}
