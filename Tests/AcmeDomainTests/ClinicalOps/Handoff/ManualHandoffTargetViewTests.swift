@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newManualHandoffTarget("code-953", name: "name-209")
        let view = ClinicalOps.toManualHandoffTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toManualHandoffTargetViews([item, item]).count == 2)
    }
}
