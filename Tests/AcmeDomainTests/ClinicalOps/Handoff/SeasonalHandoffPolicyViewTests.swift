@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalHandoffPolicy("code-749", name: "name-851")
        let view = ClinicalOps.toSeasonalHandoffPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalHandoffPolicyViews([item, item]).count == 2)
    }
}
