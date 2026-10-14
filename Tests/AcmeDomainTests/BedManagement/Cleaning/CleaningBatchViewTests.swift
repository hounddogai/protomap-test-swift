@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        let view = BedManagement.toCleaningBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningBatchViews([item, item]).count == 2)
    }
}
