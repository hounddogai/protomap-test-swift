@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskVariance("code-56", title: "title-980")
        let view = ClinicalOps.toTaskVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskVarianceViews([item, item]).count == 2)
    }
}
