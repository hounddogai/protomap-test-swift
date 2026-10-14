@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyReservation("code-870", name: "name-4")
        let view = Imaging.toStudyReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyReservationViews([item, item]).count == 2)
    }
}
