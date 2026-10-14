@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        let view = Labs.toPanelReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelReservationViews([item, item]).count == 2)
    }
}
