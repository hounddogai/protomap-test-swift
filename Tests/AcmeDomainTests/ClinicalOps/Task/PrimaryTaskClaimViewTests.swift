@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryTaskClaim("code-417", label: "label-517")
        let view = ClinicalOps.toPrimaryTaskClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryTaskClaimViews([item, item]).count == 2)
    }
}
