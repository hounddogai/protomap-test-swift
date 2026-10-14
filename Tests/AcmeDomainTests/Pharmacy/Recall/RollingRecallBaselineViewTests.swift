@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingRecallBaseline("code-185", label: "label-964")
        let view = Pharmacy.toRollingRecallBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingRecallBaselineViews([item, item]).count == 2)
    }
}
