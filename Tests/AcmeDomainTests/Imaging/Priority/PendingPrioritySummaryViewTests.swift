@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingPrioritySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingPrioritySummary("code-613", name: "name-568")
        let view = Imaging.toPendingPrioritySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingPrioritySummaryViews([item, item]).count == 2)
    }
}
