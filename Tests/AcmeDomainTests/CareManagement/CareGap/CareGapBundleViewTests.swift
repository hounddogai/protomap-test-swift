@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapBundle("code-300", label: "label-140")
        let view = CareManagement.toCareGapBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapBundleViews([item, item]).count == 2)
    }
}
