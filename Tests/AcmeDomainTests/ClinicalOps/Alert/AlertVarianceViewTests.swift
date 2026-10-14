@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertVariance("code-559", label: "label-591")
        let view = ClinicalOps.toAlertVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertVarianceViews([item, item]).count == 2)
    }
}
