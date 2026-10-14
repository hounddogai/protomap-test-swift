@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        let view = ClinicalOps.toScheduledCareProtocolProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledCareProtocolProfileViews([item, item]).count == 2)
    }
}
