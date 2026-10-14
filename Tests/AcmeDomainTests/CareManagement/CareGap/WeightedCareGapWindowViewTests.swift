@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedCareGapWindow("code-731", label: "label-294")
        let view = CareManagement.toWeightedCareGapWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedCareGapWindowViews([item, item]).count == 2)
    }
}
