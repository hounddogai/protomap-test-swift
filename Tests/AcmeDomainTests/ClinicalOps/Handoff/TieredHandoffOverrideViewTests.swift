@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredHandoffOverride("code-844", title: "title-447")
        let view = ClinicalOps.toTieredHandoffOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredHandoffOverrideViews([item, item]).count == 2)
    }
}
