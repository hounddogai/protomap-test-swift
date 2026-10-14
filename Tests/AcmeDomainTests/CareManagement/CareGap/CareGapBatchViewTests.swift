@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapBatch("code-806", name: "name-917")
        let view = CareManagement.toCareGapBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapBatchViews([item, item]).count == 2)
    }
}
