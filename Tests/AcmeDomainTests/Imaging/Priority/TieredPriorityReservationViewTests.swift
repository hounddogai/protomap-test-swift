@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredPriorityReservation("code-825", title: "title-940")
        let view = Imaging.toTieredPriorityReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredPriorityReservationViews([item, item]).count == 2)
    }
}
