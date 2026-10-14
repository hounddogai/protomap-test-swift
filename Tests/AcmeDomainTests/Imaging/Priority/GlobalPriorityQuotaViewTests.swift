@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalPriorityQuota("code-796", label: "label-698")
        let view = Imaging.toGlobalPriorityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalPriorityQuotaViews([item, item]).count == 2)
    }
}
