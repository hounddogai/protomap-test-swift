@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyProgramVariance("code-983", title: "title-805")
        let view = CareManagement.toLegacyProgramVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyProgramVarianceViews([item, item]).count == 2)
    }
}
