@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newHandoffBundle("code-341", title: "title-505")
        let view = ClinicalOps.toHandoffBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toHandoffBundleViews([item, item]).count == 2)
    }
}
