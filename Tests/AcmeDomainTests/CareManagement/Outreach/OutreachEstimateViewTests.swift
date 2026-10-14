@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachEstimate("code-490", name: "name-771")
        let view = CareManagement.toOutreachEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachEstimateViews([item, item]).count == 2)
    }
}
