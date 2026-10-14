@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackProgramVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        let view = CareManagement.toFallbackProgramVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackProgramVarianceViews([item, item]).count == 2)
    }
}
