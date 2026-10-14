@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertQuota("code-157", name: "name-488")
        let view = ClinicalOps.toAlertQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertQuotaViews([item, item]).count == 2)
    }
}
