@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredTaskPolicy("code-270", title: "title-992")
        let view = ClinicalOps.toTieredTaskPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredTaskPolicyViews([item, item]).count == 2)
    }
}
