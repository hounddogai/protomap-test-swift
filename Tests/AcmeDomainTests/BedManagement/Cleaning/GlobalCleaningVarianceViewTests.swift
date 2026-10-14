@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCleaningVariance("code-973", label: "label-333")
        let view = BedManagement.toGlobalCleaningVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCleaningVarianceViews([item, item]).count == 2)
    }
}
