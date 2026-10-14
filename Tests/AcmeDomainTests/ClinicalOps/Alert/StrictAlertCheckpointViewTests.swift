@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictAlertCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictAlertCheckpoint("code-995", name: "name-343")
        let view = ClinicalOps.toStrictAlertCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictAlertCheckpointViews([item, item]).count == 2)
    }
}
