@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedRoundingPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedRoundingPreference("code-818", label: "label-59")
        let view = ClinicalOps.toWeightedRoundingPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedRoundingPreferenceViews([item, item]).count == 2)
    }
}
