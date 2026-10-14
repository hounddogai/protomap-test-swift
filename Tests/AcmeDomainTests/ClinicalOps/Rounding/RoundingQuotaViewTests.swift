@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRoundingQuota("code-300", title: "title-236")
        let view = ClinicalOps.toRoundingQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRoundingQuotaViews([item, item]).count == 2)
    }
}
