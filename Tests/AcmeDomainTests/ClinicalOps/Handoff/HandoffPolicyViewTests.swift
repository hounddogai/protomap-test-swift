@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newHandoffPolicy("code-707", title: "title-694")
        let view = ClinicalOps.toHandoffPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toHandoffPolicyViews([item, item]).count == 2)
    }
}
