@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalProgramBundle("code-499", title: "title-626")
        let view = CareManagement.toSeasonalProgramBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalProgramBundleViews([item, item]).count == 2)
    }
}
