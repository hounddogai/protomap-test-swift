@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertSnapshot("code-861", label: "label-353")
        let view = ClinicalOps.toAlertSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertSnapshotViews([item, item]).count == 2)
    }
}
