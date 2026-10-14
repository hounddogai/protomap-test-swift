@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalHandoffQuota("code-837", title: "title-334")
        let view = ClinicalOps.toGlobalHandoffQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalHandoffQuotaViews([item, item]).count == 2)
    }
}
