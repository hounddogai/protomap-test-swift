@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultCareProtocolSummary("code-671", name: "name-184")
        let view = ClinicalOps.toDefaultCareProtocolSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultCareProtocolSummaryViews([item, item]).count == 2)
    }
}
