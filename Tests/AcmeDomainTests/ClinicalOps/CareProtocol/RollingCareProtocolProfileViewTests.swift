@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingCareProtocolProfile("code-782", title: "title-989")
        let view = ClinicalOps.toRollingCareProtocolProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingCareProtocolProfileViews([item, item]).count == 2)
    }
}
