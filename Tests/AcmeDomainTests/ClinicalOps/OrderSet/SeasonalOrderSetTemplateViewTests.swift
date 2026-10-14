@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        let view = ClinicalOps.toSeasonalOrderSetTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalOrderSetTemplateViews([item, item]).count == 2)
    }
}
