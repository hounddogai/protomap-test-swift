@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingInteractionSegment("code-666", label: "label-653")
        let view = Pharmacy.toRollingInteractionSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingInteractionSegmentViews([item, item]).count == 2)
    }
}
