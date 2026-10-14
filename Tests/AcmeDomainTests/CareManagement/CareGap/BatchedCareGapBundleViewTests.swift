@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedCareGapBundle("code-473", name: "name-849")
        let view = CareManagement.toBatchedCareGapBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedCareGapBundleViews([item, item]).count == 2)
    }
}
