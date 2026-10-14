@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("code-989", title: "title-515")
        let view = ClinicalOps.toAdaptiveCareProtocolProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveCareProtocolProfileViews([item, item]).count == 2)
    }
}
