@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        let view = ClinicalOps.toScheduledHandoffWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledHandoffWindowViews([item, item]).count == 2)
    }
}
