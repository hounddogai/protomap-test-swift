@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackProgramMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackProgramMetric("code-20", name: "name-880")
        let view = CareManagement.toFallbackProgramMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackProgramMetricViews([item, item]).count == 2)
    }
}
