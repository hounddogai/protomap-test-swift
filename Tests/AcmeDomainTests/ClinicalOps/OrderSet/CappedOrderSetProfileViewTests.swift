@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedOrderSetProfile("code-541", title: "title-250")
        let view = ClinicalOps.toCappedOrderSetProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedOrderSetProfileViews([item, item]).count == 2)
    }
}
