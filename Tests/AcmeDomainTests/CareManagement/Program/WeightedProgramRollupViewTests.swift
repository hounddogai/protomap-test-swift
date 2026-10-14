@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedProgramRollup("code-216", label: "label-839")
        let view = CareManagement.toWeightedProgramRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedProgramRollupViews([item, item]).count == 2)
    }
}
