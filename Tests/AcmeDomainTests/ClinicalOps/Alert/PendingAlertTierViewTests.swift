@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingAlertTier("code-395", name: "name-311")
        let view = ClinicalOps.toPendingAlertTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingAlertTierViews([item, item]).count == 2)
    }
}
