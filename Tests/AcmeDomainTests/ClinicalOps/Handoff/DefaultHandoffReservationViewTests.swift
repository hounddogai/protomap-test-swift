@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultHandoffReservation("code-104", title: "title-635")
        let view = ClinicalOps.toDefaultHandoffReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultHandoffReservationViews([item, item]).count == 2)
    }
}
