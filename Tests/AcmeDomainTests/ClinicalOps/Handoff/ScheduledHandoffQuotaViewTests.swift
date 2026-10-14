@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        let view = ClinicalOps.toScheduledHandoffQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledHandoffQuotaViews([item, item]).count == 2)
    }
}
