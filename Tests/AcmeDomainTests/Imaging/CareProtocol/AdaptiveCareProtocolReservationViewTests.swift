@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveCareProtocolReservation("code-731", name: "name-232")
        let view = Imaging.toAdaptiveCareProtocolReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveCareProtocolReservationViews([item, item]).count == 2)
    }
}
