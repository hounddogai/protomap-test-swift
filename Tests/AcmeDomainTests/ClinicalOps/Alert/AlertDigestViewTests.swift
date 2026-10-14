@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertDigest("code-372", label: "label-275")
        let view = ClinicalOps.toAlertDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertDigestViews([item, item]).count == 2)
    }
}
