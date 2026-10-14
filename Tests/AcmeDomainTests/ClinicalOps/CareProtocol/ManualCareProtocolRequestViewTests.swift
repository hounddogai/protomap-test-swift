@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualCareProtocolRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newManualCareProtocolRequest("code-921", name: "name-106")
        let view = ClinicalOps.toManualCareProtocolRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toManualCareProtocolRequestViews([item, item]).count == 2)
    }
}
