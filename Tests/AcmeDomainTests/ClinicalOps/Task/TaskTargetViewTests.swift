@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskTarget("code-628", label: "label-160")
        let view = ClinicalOps.toTaskTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskTargetViews([item, item]).count == 2)
    }
}
