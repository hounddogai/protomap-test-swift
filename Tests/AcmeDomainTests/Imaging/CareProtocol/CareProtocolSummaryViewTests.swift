@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        let view = Imaging.toCareProtocolSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolSummaryViews([item, item]).count == 2)
    }
}
