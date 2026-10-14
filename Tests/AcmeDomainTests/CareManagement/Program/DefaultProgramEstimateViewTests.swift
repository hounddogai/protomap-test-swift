@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultProgramEstimate("code-263", name: "name-849")
        let view = CareManagement.toDefaultProgramEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultProgramEstimateViews([item, item]).count == 2)
    }
}
